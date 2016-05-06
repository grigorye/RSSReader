//
//  RSSSession.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import GEKeyPaths
import Foundation
import CoreData

let lastTagsDataPath = "\(NSTemporaryDirectory())/lastTags"

private var batchSavingDisabled: Bool {
	return !defaults.batchSavingEnabled
}

var itemsAreSortedByLoadDate: Bool {
	return defaults.itemsAreSortedByLoadDate
}

public class RSSSession: NSObject {
	public enum Error: ErrorType {
		case AuthenticationFailed(underlyingError: ErrorType)
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
	public init(loginAndPassword: LoginAndPassword) {
		self.loginAndPassword = loginAndPassword
	}
}

public extension RSSSession {
	public var authToken: String! {
		get {
			return defaults.authToken
		}
		set {
			defaults.authToken = newValue
		}
	}
}

extension RSSSession {
	typealias TaskCompletionHandler = ProgressEnabledURLSessionTaskGenerator.HTTPDataTaskCompletionHandler
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithURL(url: NSURL, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask? {
		precondition(nil != self.authToken)
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
		let url: NSURL = {
			let $ = NSURLComponents()
			$.scheme = "https"
			$.host = "www.inoreader.com"
			$.path = path
			return $.URL!
		}()
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, completionHandler: completionHandler)
	}
	func dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString: String, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask? {
		let baseURL: NSURL = {
			let $ = NSURLComponents()
			$.scheme = "https"
			$.host = "www.inoreader.com"
			$.path = "/"
			return $.URL!
		}()
		let url = NSURL(string: relativeString, relativeToURL: baseURL)!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL((url), completionHandler: completionHandler)
	}
	// MARK: -
	public func authenticate(completionHandler: (ErrorType?) -> Void) {
		let url: NSURL = {
			let $ = NSURLComponents()
			$.scheme = "https"
			$.host = "www.inoreader.com"
			$.path = "/accounts/ClientLogin"
			return $.URL!
		}()
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
		$(request)
		let sessionTask = progressEnabledURLSessionTaskGenerator.dataTaskForHTTPRequest(request) { data, httpResponse, error in
			if let error = error {
				let adjustedError: ErrorType = {
					switch error {
					case GEBase.URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus(let httpResponse):
						guard httpResponse.statusCode == 401 else {
							return error
						}
						return Error.AuthenticationFailed(underlyingError: error)
					default:
						return error
					}
				}()
				completionHandler($(adjustedError))
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
			completionHandler(nil)
		}!
		sessionTask.resume()
	}
	// MARK: -
	func reauthenticate(completionHandler: (ErrorType?) -> Void) {
		authenticate(completionHandler)
	}
	// MARK: -
	public func updateUserInfo(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/user-info"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
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
					completionHandler($(error))
				}
			}
		}!
		sessionTask.resume()
	}
	public func uploadTag(tag: String, mark: Bool, forItem item: Item, completionHandler: (ErrorType?) -> Void) {
		let command = mark ? "a" : "r"
		let path = "/reader/api/0/edit-tag?\(command)=\(tag)&i=\(item.itemID)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let data = data {
				let body = NSString(data: data, encoding: NSUTF8StringEncoding)
				$(body)
			}
			completionHandler(error)
		}!
		sessionTask.resume()
	}
	public func updateUnreadCounts(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/unread-count"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
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
					completionHandler($(error))
				}
			}
		}!
		sessionTask.resume()
	}
	func updateTagsFromData(data: NSData, completionHandler: (ErrorType?) -> Void) {
		backgroundQueueManagedObjectContext.performBlock {
			do {
				try importItemsFromJsonData(data, type: Folder.self, elementName: "tags", managedObjectContext: (backgroundQueueManagedObjectContext)) { (tag, json) in
					assert(tag.managedObjectContext == backgroundQueueManagedObjectContext)
					if _1 {
						try tag.importFromJson(json)
					}
				}
				try backgroundQueueManagedObjectContext.save()
				completionHandler(nil)
			} catch {
				completionHandler($(error))
			}
		}
	}
	public func updateTags(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/tag/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			try! data.writeToFile(lastTagsDataPath, options: .DataWritingAtomic)
			self.updateTagsFromData(data!, completionHandler: completionHandler)
		}!
		sessionTask.resume()
	}
	public func updateStreamPreferences(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/preference/stream/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
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
					completionHandler($(error))
				}
			}
		}!
		sessionTask.resume()
	}
	public func updateSubscriptions(completionHandler: (ErrorType?) -> Void) {
		let path = "/reader/api/0/subscription/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			backgroundQueueManagedObjectContext.performBlock {
				do {
					try importItemsFromJsonData(data, type: Subscription.self, elementName: "subscriptions", managedObjectContext: backgroundQueueManagedObjectContext) { (subscription, json) in
						try subscription.importFromJson(json)
					}
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error))
				}
			}
		}!
		sessionTask.resume()
	}
	public func markAllAsRead(container: Container, completionHandler: (ErrorType?) -> Void) {
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
				backgroundQueueManagedObjectContext.performBlock {
					do {
						try backgroundQueueManagedObjectContext.save()
						completionHandler(nil)
					} catch {
						completionHandler($(error))
					}
				}
			} catch {
				completionHandler($(error))
			}
		}!
		sessionTask.resume()
	}
	// MARK: -
	public func streamContents(container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: NSDate, completionHandler: (continuation: String?, items: [Item]!, error: ErrorType?) -> Void) {
		var queryComponents = [String]()
		if let continuation = continuation {
			queryComponents += ["c=\($(continuation))"]
		}
		if let excludedCategory = excludedCategory {
			queryComponents += ["xt=\($(excludedCategory.streamID))"]
		}
		queryComponents += ["n=\(count)"]
		let streamIDPercentEncoded = container.streamID.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
		let querySuffix = URLQuerySuffixFromComponents(queryComponents)
		let relativeString = "/reader/api/0/stream/contents/\(streamIDPercentEncoded)\(querySuffix)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(continuation: nil, items: nil, error: error)
				return
			}
			let subscriptionObjectID = (container as? Subscription)?.objectID
			let managedObjectContext = backgroundQueueManagedObjectContext
			managedObjectContext.performBlock {
				do {
					let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
					guard let json = jsonObject as? [String : AnyObject] else {
						throw Error.JsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					let continuation = json["continuation"] as? String
					let items = try importItemsFromJson(json, type: Item.self, elementName: "items", managedObjectContext: managedObjectContext) { (item, itemJson) in
						let subscription: Subscription? = {
							guard let subscriptionObjectID = subscriptionObjectID else {
								return nil
							}
							return (managedObjectContext.objectWithID(subscriptionObjectID) as! Subscription)
						}()
						try item.importFromJson(itemJson, subscription: subscription)
						item.loadDate = loadDate
						if batchSavingDisabled {
							try backgroundQueueManagedObjectContext.save()
						}
					}
					if let excludedCategory = excludedCategory {
						let lastItem = items.last
						let containerInBackground = backgroundQueueManagedObjectContext.sameObject(container)
						let excludedCategoryInBackground = backgroundQueueManagedObjectContext.sameObject(excludedCategory)
						let fetchRequest: NSFetchRequest = {
							let $ = NSFetchRequest(entityName: Item.entityName())
							$.predicate = NSPredicate(format: "(loadDate != %@) && (date < %@) && (subscription == %@) && SUBQUERY(\(Item.self••{$0.categories}), $x, $x.\(Folder.self••{$0.streamID}) ENDSWITH %@).@count == 0", argumentArray: [loadDate, lastItem?.date ?? NSDate.distantFuture(), containerInBackground, excludedCategoryInBackground.streamID])
							return $
						}()
						let itemsNowAssignedToExcludedCategory = try! backgroundQueueManagedObjectContext.executeFetchRequest(fetchRequest) as! [Item]
						for item in itemsNowAssignedToExcludedCategory {
							item.categories.unionInPlace([excludedCategoryInBackground])
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
					completionHandler(continuation: nil, items: nil, error: $(error))
				}
			}
		}!
		sessionTask.resume()
	}
}