//
//  RSSSession.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation
import CoreData

let lastTagsFileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/lastTags")

private var batchSavingDisabled: Bool {
	return !defaults.batchSavingEnabled
}

var itemsAreSortedByLoadDate: Bool {
	return defaults.itemsAreSortedByLoadDate
}

public class RSSSession: NSObject {
	public enum Error: ErrorProtocol {
		case AuthenticationFailed(underlyingError: ErrorProtocol)
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
	func dataTaskForAuthenticatedHTTPRequestWithURL(_ url: URL, completionHandler: TaskCompletionHandler) -> URLSessionDataTask? {
		precondition(nil != self.authToken)
		let request: URLRequest = {
			var $ = URLRequest(url: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			$.addValue(self.inoreaderAppID, forHTTPHeaderField: "AppId")
			$.addValue(self.inoreaderAppKey, forHTTPHeaderField: "AppKey")
			return $
		}()
		return progressEnabledURLSessionTaskGenerator.dataTask(forHTTPRequest: request, completionHandler: completionHandler)
	}
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequest(withPath path: String, completionHandler: TaskCompletionHandler) -> URLSessionDataTask? {
		let url: URL = {
			let $ = NSURLComponents()
			$.scheme = "https"
			$.host = "www.inoreader.com"
			$.path = path
			return $.url!
		}()
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, completionHandler: completionHandler)
	}
	func dataTaskForAuthenticatedHTTPRequest(withRelativeString relativeString: String, completionHandler: TaskCompletionHandler) -> URLSessionDataTask? {
		let baseURL: URL = {
			let $ = NSURLComponents()
			$.scheme = "https"
			$.host = "www.inoreader.com"
			$.path = "/"
			return $.url!
		}()
		let url = URL(string: relativeString, relativeTo: baseURL)!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL((url), completionHandler: completionHandler)
	}
	// MARK: -
	public func authenticate(_ completionHandler: (ErrorProtocol?) -> Void) {
		let url: URL = {
			let $ = NSURLComponents()
			$.scheme = "https"
			$.host = "www.inoreader.com"
			$.path = "/accounts/ClientLogin"
			return $.url!
		}()
		let request: URLRequest = {
			var $ = URLRequest(url: url)
			$.httpMethod = "POST"
			$.httpBody = {
				let allowedCharacters = NSCharacterSet.alphanumerics()
				let loginEncoded = self.loginAndPassword.login?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
				let passwordEncoded = self.loginAndPassword.password?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
				let body: String = {
					if passwordEncoded == nil && loginEncoded == nil {
						return ""
					}
					return "Email=\(loginEncoded!)&Passwd=\(passwordEncoded!)"
				}()
				return body.data(using: String.Encoding.utf8, allowLossyConversion: false)
			}()
			return $
		}()
		$(request)
		let sessionTask = progressEnabledURLSessionTaskGenerator.dataTask(forHTTPRequest: request) { data, httpResponse, error in
			if let error = error {
				let adjustedError: ErrorProtocol = {
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
			let data = data!
			let authToken: String? = {
				let body = String(data: data, encoding: String.Encoding.utf8)!
				let authLocationIndex = body.range(of: "Auth=")!.upperBound
				let authTail = body.substring(from: authLocationIndex)
				let lastIndexInAuthTail = authTail.range(of: "\n")!.lowerBound
				let $ = authTail.substring(to: lastIndexInAuthTail)
				return $
			}()
			self.authToken = authToken
			completionHandler(nil)
		}!
		sessionTask.resume()
	}
	// MARK: -
	func reauthenticate(completionHandler: (ErrorProtocol?) -> Void) {
		authenticate(completionHandler)
	}
	// MARK: -
	public func updateUserInfo(completionHandler: (ErrorProtocol?) -> Void) {
		let path = "/reader/api/0/user-info"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let data = data!
			backgroundQueueManagedObjectContext.perform {
				do {
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
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
	public func uploadTag(_ tag: String, mark: Bool, forItem item: Item, completionHandler: (ErrorProtocol?) -> Void) {
		let command = mark ? "a" : "r"
		let path = "/reader/api/0/edit-tag?\(command)=\(tag)&i=\(item.itemID)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let data = data {
				let body = String(data: data, encoding: String.Encoding.utf8)
				$(body)
			}
			completionHandler(error)
		}!
		sessionTask.resume()
	}
	public func updateUnreadCounts(completionHandler: (ErrorProtocol?) -> Void) {
		let path = "/reader/api/0/unread-count"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let data = data!
			backgroundQueueManagedObjectContext.perform {
				var containers = [Container]()
				do {
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
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
	func updateTags(from data: Data, completionHandler: (ErrorProtocol?) -> Void) {
		backgroundQueueManagedObjectContext.perform {
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
	public func updateTags(completionHandler: (ErrorProtocol?) -> Void) {
		let path = "/reader/api/0/tag/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let data = data!
			try! data.write(to: lastTagsFileURL, options: .dataWritingAtomic)
			self.updateTags(from: data, completionHandler: completionHandler)
		}!
		sessionTask.resume()
	}
	public func updateStreamPreferences(completionHandler: (ErrorProtocol?) -> Void) {
		let path = "/reader/api/0/preference/stream/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let data = data!
			backgroundQueueManagedObjectContext.perform {
				do {
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
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
	public func updateSubscriptions(completionHandler: (ErrorProtocol?) -> Void) {
		let path = "/reader/api/0/subscription/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let data = data!
			backgroundQueueManagedObjectContext.perform {
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
	public func markAllAsRead(_ container: Container, completionHandler: (ErrorProtocol?) -> Void) {
		let containerIDPercentEncoded = container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics())!
		let newestItemTimestampUsec = container.newestItemDate.timestampUsec
		let relativeString = "/reader/api/0/mark-all-as-read?s=\(containerIDPercentEncoded)&ts=\(newestItemTimestampUsec)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: relativeString) { data, httpResponse, error in
			do {
				if let error = error {
					throw error
				}
				let data = data!
				guard let body = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
					throw Error.BadResponseDataForMarkAsRead(data: data)
				}
				guard body == "OK" else {
					throw Error.UnexpectedResponseTextForMarkAsRead(body: body as String)
				}
				backgroundQueueManagedObjectContext.perform {
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
	public func streamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: Date, completionHandler: (continuation: String?, items: [Item]?, error: ErrorProtocol?) -> Void) {
		var queryComponents = [String]()
		if let continuation = continuation {
			queryComponents += ["c=\($(continuation))"]
		}
		if let excludedCategory = excludedCategory {
			queryComponents += ["xt=\($(excludedCategory.streamID))"]
		}
		queryComponents += ["n=\(count)"]
		let streamIDPercentEncoded = container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics())!
		let querySuffix = URLQuerySuffix(fromComponents: queryComponents)
		let relativeString = "/reader/api/0/stream/contents/\(streamIDPercentEncoded)\(querySuffix)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: relativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(continuation: nil, items: nil, error: error)
				return
			}
			let data = data!
			let subscriptionObjectID = (container as? Subscription)?.objectID
			let managedObjectContext = backgroundQueueManagedObjectContext
			managedObjectContext.perform {
				do {
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
					guard let json = jsonObject as? [String : AnyObject] else {
						throw Error.JsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					let continuation = json["continuation"] as? String
					let items = try importItemsFromJson(json, type: Item.self, elementName: "items", managedObjectContext: managedObjectContext) { (item, itemJson) in
						let subscription: Subscription? = {
							guard let subscriptionObjectID = subscriptionObjectID else {
								return nil
							}
							return (managedObjectContext.object(with: subscriptionObjectID) as! Subscription)
						}()
						try item.importFromJson(itemJson, subscription: subscription)
						item.loadDate = loadDate
						if batchSavingDisabled {
							try backgroundQueueManagedObjectContext.save()
						}
					}
					if let excludedCategory = excludedCategory {
						let lastItem = items.last
						let containerInBackground = backgroundQueueManagedObjectContext.sameObject(as: container)
						let excludedCategoryInBackground = backgroundQueueManagedObjectContext.sameObject(as: excludedCategory)
						let fetchRequest: NSFetchRequest<Item> = {
							let $ = NSFetchRequest<Item>(entityName: Item.entityName())
							$.predicate = Predicate(format: "(loadDate != %@) && (date < %@) && (subscription == %@) && SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0", argumentArray: [loadDate, lastItem?.date ?? NSDate.distantFuture(), containerInBackground, excludedCategoryInBackground.streamID])
							return $
						}()
						let itemsNowAssignedToExcludedCategory = try! backgroundQueueManagedObjectContext.fetch(fetchRequest)
						for item in itemsNowAssignedToExcludedCategory {
							item.categories.formUnion([excludedCategoryInBackground])
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
