//
//  RSSSession.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

var batchSavingDisabled: Bool {
	return defaults.batchSavingDisabled
}

var itemsAreSortedByLoadDate: Bool {
	return defaults.itemsAreSortedByLoadDate
}

class RSSSession: NSObject {
	enum Error: ErrorType {
		case JsonObjectIsNotDictionary(jsonObject: AnyObject)
		case JsonMissingUserID(json: [String: AnyObject])
		case JsonMissingUnreadCounts(json: [String: AnyObject])
		case ItemJsonMissingID(itemJson: [String: AnyObject])
		case JsonMissingStreamPrefs(json: [String: AnyObject])
		case UnexpectedResponseTextForMarkAsRead(body: String)
		case BadResponseDataForMarkAsRead(data: NSData)
	}
	let inoreaderAppID = "1000001375"
	let inoreaderAppKey = "r3O8gX6FPdFaOXE3x4HypYHO2LTCNuDS"
	let loginAndPassword: LoginAndPassword
	init(loginAndPassword: LoginAndPassword) {
		self.loginAndPassword = loginAndPassword
	}
	typealias TaskCompletionHandler = ProgressEnabledURLSessionTaskGenerator.HTTPDataTaskCompletionHandler
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithURL(url: NSURL, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask? {
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			$.addValue(self.inoreaderAppID, forHTTPHeaderField: "AppId")
			$.addValue(self.inoreaderAppKey, forHTTPHeaderField: "AppKey")
			return $
		}()
		return progressEnabledURLSessionTaskGenerator.dataTaskForHTTPRequest(request, completionHandler: completionHandler)
	}
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithPath(path: String, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask? {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: path)!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, completionHandler: completionHandler)
	}
	func dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString: String, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask? {
		let url = NSURL(string: relativeString, relativeToURL: NSURL(scheme: "https", host: "www.inoreader.com", path: "/"))!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, completionHandler: completionHandler)
	}
	// MARK: -
	func authenticate(completionHandler: (ErrorType?) -> Void) {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: "/accounts/ClientLogin")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.HTTPMethod = "POST"
			$.HTTPBody = {
				let allowedCharacters = NSCharacterSet.alphanumericCharacterSet()
				let loginEncoded = self.loginAndPassword.login?.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
				let passwordEncoded = self.loginAndPassword.password?.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
				let body: NSString = {
					if passwordEncoded == nil && loginEncoded == nil {
						return ""
					}
					return "Email=\(loginEncoded!)&Passwd=\(passwordEncoded!)"
				}()
				return body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
			}()
			return $
		}()
		let sessionTask = progressEnabledURLSessionTaskGenerator.dataTaskForHTTPRequest(request) { data, httpResponse, error in
			if let error = error {
				completionHandler($(error).$())
				return
			}
			let authToken: String? = {
				let body = NSString(data: data, encoding: NSUTF8StringEncoding)!
				let authLocation = NSMaxRange(body.rangeOfString("Auth="))
				let authRangeMax = body.rangeOfString("\n", options: [], range: NSMakeRange(authLocation, body.length - authLocation)).location
				let $ = body.substringWithRange(NSMakeRange(authLocation, authRangeMax - authLocation))
				return $
			}()
			self.authToken = authToken
		}!
		sessionTask.resume()
	}
	// MARK: -
	func reauthenticate(completionHandler: (ErrorType?) -> Void) {
		authenticate(completionHandler)
	}
	// MARK: -
	func updateUserInfo(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/user-info"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				do {
					let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
					guard let json = jsonObject as? [String : AnyObject] else {
						throw Error.JsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					guard let userID = json["userId"] as? String else {
						throw Error.JsonMissingUserID(json: json)
					}
					let id = "user/\(userID)/\(readTagSuffix)"
					try insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: backgroundQueueManagedObjectContext)
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error).$())
				}
			}
		}!
		sessionTask.resume()
	}
	func uploadTag(tag: String, mark: Bool, forItem item: Item, completionHandler: (ErrorType?) -> Void) {
		let command = mark ? "a" : "r"
		let path = "/reader/api/0/edit-tag?\(command)=\(tag)&i=\(item.itemID)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			completionHandler(error)
		}!
		sessionTask.resume()
	}
	func updateUnreadCounts(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/unread-count?output=json"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				var containers = [Container]()
				do {
					let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
					guard let json = jsonObject as? [String : AnyObject] else {
						throw Error.JsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					guard let itemJsons = json["unreadcounts"] as? [[String : AnyObject]] else {
						throw Error.JsonMissingUnreadCounts(json: json)
					}
					for itemJson in itemJsons {
						guard let itemID = itemJson["id"] as? String else {
							throw Error.ItemJsonMissingID(itemJson: itemJson)
						}
						let container: Container = try {
							if itemID.hasPrefix("feed/http") {
								let type = Subscription.self
								return try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: backgroundQueueManagedObjectContext)
							}
							else {
								let type = Folder.self
								return try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: backgroundQueueManagedObjectContext)
							}
						}()
						container.importFromUnreadCountJson(itemJson)
						containers += [container]
					}
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error).$())
				}
			}
		}!
		sessionTask.resume()
	}
	func updateTags(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/tag/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				do {
					try importItemsFromJsonData(data!, type: Folder.self, elementName: "tags", managedObjectContext: backgroundQueueManagedObjectContext) { (tag, json) in
						try tag.importFromJson(json)
					}
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error).$())
				}
			}
		}!
		sessionTask.resume()
	}
	func updateStreamPreferences(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/preference/stream/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				do {
					let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
					guard let json = jsonObject as? [String : AnyObject] else {
						throw Error.JsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					guard let streamprefsJson: AnyObject = json["streamprefs"] else {
						throw Error.JsonMissingStreamPrefs(json: json)
					}
					try Container.importStreamPreferencesJson(streamprefsJson, managedObjectContext: backgroundQueueManagedObjectContext)
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error).$())
				}
			}
		}!
		sessionTask.resume()
	}
	func updateSubscriptions(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/subscription/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				do {
					try importItemsFromJsonData(data, type: Subscription.self, elementName: "subscriptions", managedObjectContext: backgroundQueueManagedObjectContext) { (subscription, json) in
						try subscription.importFromJson(json)
					}
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error).$())
				}
			}
		}!
		sessionTask.resume()
	}
	func markAllAsRead(container: Container, completionHandler: (ErrorType?) -> Void) {
		let containerIDPercentEncoded = container.streamID.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
		let newestItemTimestampUsec = container.newestItemDate.timestampUsec
		let relativeString = "/reader/api/0/mark-all-as-read?s=\(containerIDPercentEncoded)&ts=\(newestItemTimestampUsec)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString) { data, httpResponse, error in
			do {
				if let error = error {
					throw error
				}
				guard let body = NSString(data: data, encoding: NSUTF8StringEncoding) else {
					throw Error.BadResponseDataForMarkAsRead(data: data)
				}
				guard body == "OK" else {
					throw Error.UnexpectedResponseTextForMarkAsRead(body: body as String)
				}
				let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
				backgroundQueueManagedObjectContext.performBlock {
					do {
						try backgroundQueueManagedObjectContext.save()
						completionHandler(nil)
					} catch {
						completionHandler($(error).$())
					}
				}
			} catch {
				completionHandler($(error).$())
			}
		}!
		sessionTask.resume()
	}
	// MARK: -
	func streamContents(container: Container, excludedCategory: Folder?, continuation: String?, loadDate: NSDate, completionHandler: (continuation: String?, items: [Item]!, error: ErrorType?) -> Void) {
		var queryComponents = [String]()
		if let continuation = continuation {
			queryComponents += ["c=\(continuation)"]
		}
		if let excludedCategory = excludedCategory {
			queryComponents += ["xt=\(excludedCategory.streamID)"]
		}
		let subscriptionIDPercentEncoded = container.streamID.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
		let querySuffix = URLQuerySuffixFromComponents(queryComponents)
		let relativeString = "/reader/api/0/stream/contents/\(subscriptionIDPercentEncoded)\(querySuffix)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(continuation: nil, items: nil, error: error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				do {
					let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
					guard let json = jsonObject as? [String : AnyObject] else {
						throw Error.JsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					let continuation = json["continuation"] as? String
					let items = try importItemsFromJson(json, type: Item.self, elementName: "items", managedObjectContext: backgroundQueueManagedObjectContext) { (item, itemJson) in
						try item.importFromJson(itemJson)
						if itemsAreSortedByLoadDate {
							item.loadDate = loadDate
						}
						if batchSavingDisabled {
							try backgroundQueueManagedObjectContext.save()
						}
					}
					if !batchSavingDisabled {
						try backgroundQueueManagedObjectContext.save()
					}
					else {
						assert(!backgroundQueueManagedObjectContext.hasChanges)
					}
					completionHandler(continuation: continuation, items: items, error: nil)
				} catch {
					completionHandler(continuation: nil, items: nil, error: $(error).$())
				}
			}
		}!
		sessionTask.resume()
	}
}