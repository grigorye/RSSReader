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

public enum RSSSessionError: ErrorProtocol {
	case authenticationFailed(underlyingError: ErrorProtocol)
	case jsonObjectIsNotDictionary(jsonObject: AnyObject)
	case jsonMissingUserID(json: [String: AnyObject])
	case jsonMissingUnreadCounts(json: [String: AnyObject])
	case itemJsonMissingID(itemJson: [String: AnyObject])
	case jsonMissingStreamPrefs(json: [String: AnyObject])
	case unexpectedResponseTextForMarkAsRead(body: String)
	case badResponseDataForMarkAsRead(data: NSData)
	case pushTagsFailed(underlyingErrors: [ErrorProtocol])
}

public class RSSSession: NSObject {
	let inoreaderAppID = "1000001375"
	let inoreaderAppKey = "r3O8gX6FPdFaOXE3x4HypYHO2LTCNuDS"
	let loginAndPassword: LoginAndPassword
	public init(loginAndPassword: LoginAndPassword) {
		self.loginAndPassword = loginAndPassword
	}
}

public extension RSSSession {
	typealias Error = RSSSessionError
	public var authToken: String! {
		get {
			return defaults.authToken
		}
		set {
			defaults.authToken = newValue
		}
	}
}

func itemsImportedFromStreamJson(_ json: Json, loadDate: Date, container: Container, excludedCategory: Folder?, managedObjectContext: NSManagedObjectContext) throws -> [Item] {
	let subscription = container as? Subscription
	let items = try importItemsFromJson(json, type: Item.self, elementName: "items", managedObjectContext: managedObjectContext) { (item, itemJson) in
		try item.importFromJson(itemJson, subscription: subscription)
		item.loadDate = loadDate
		if batchSavingDisabled {
			try managedObjectContext.save()
		}
	}
	if let excludedCategory = excludedCategory {
		let lastItem = items.last
		let fetchRequest = Item.fetchRequestForEntity() … {
			$0.predicate = Predicate(
				format: "(loadDate != %@) && (date < %@) && (subscription == %@) && SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0",
				argumentArray: [
					loadDate,
					lastItem?.date ?? NSDate.distantFuture(),
					container,
					excludedCategory.streamID
				]
			)
		}
		let itemsNowAssignedToExcludedCategory = try! managedObjectContext.fetch(fetchRequest)
		for item in itemsNowAssignedToExcludedCategory {
			item.categories.formUnion([excludedCategory])
		}
	}
	if !batchSavingDisabled {
		try managedObjectContext.save()
	}
	else {
		assert(!managedObjectContext.hasChanges)
	}
	return items
}

func continuationAndItemsImportedFromStreamData(_ data: Data, loadDate: Date, container: Container, excludedCategory: Folder?, managedObjectContext: NSManagedObjectContext) throws -> (String?, [Item]) {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? Json else {
		throw RSSSessionError.jsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	let continuation = json["continuation"] as? String
	let items = try itemsImportedFromStreamJson(json, loadDate: loadDate, container: container, excludedCategory: excludedCategory, managedObjectContext: managedObjectContext)
	return (continuation, items)
}

extension RSSSession {
	typealias TaskCompletionHandler = ProgressEnabledURLSessionTaskGenerator.HTTPDataTaskCompletionHandler
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithURL(_ url: URL, httpMethod: String = "GET", completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		precondition(nil != self.authToken)
		let request = URLRequest(url: url) … {
			$0.httpMethod = httpMethod
			$0.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			$0.addValue(self.inoreaderAppID, forHTTPHeaderField: "AppId")
			$0.addValue(self.inoreaderAppKey, forHTTPHeaderField: "AppKey")
		}
		return progressEnabledURLSessionTaskGenerator.dataTask(for: request, completionHandler: completionHandler)
	}
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequest(withPath path: String, httpMethod: String = "GET", completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let url: URL = {
			let components = NSURLComponents() … {
				$0.scheme = "https"
				$0.host = "www.inoreader.com"
				$0.path = path
			}
			return components.url!
		}()
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, httpMethod: httpMethod, completionHandler: completionHandler)
	}
	func dataTaskForAuthenticatedHTTPRequest(withRelativeString relativeString: String, httpMethod: String = "GET", completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let baseURL: URL = {
			let components = NSURLComponents() … {
				$0.scheme = "https"
				$0.host = "www.inoreader.com"
				$0.path = "/"
			}
			return components.url!
		}()
		let url = URL(string: relativeString, relativeTo: baseURL)!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL((url), httpMethod: httpMethod, completionHandler: completionHandler)
	}
	// MARK: -
	public func authenticate(_ completionHandler: (ErrorProtocol?) -> Void) {
		let url: URL = {
			let components = NSURLComponents() … {
				$0.scheme = "https"
				$0.host = "www.inoreader.com"
				$0.path = "/accounts/ClientLogin"
			}
			return components.url!
		}()
		let request = URLRequest(url: url) … {
			$0.httpMethod = "POST"
			$0.httpBody = {
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
		}
		$(request)
		let sessionTask = progressEnabledURLSessionTaskGenerator.dataTask(for: request) { data, httpResponse, error in
			if let error = error {
				let adjustedError: ErrorProtocol = {
					switch error {
					case GEBase.URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus(let httpResponse):
						guard httpResponse.statusCode == 401 else {
							return error
						}
						return Error.authenticationFailed(underlyingError: error)
					default:
						return error
					}
				}()
				completionHandler($(adjustedError))
				return
			}
			let data = data!
			let authToken: String = {
				let body = String(data: data, encoding: String.Encoding.utf8)!
				let authLocationIndex = body.range(of: "Auth=")!.upperBound
				let authTail = body.substring(from: authLocationIndex)
				let lastIndexInAuthTail = authTail.range(of: "\n")!.lowerBound
				let $ = authTail.substring(to: lastIndexInAuthTail)
				return $
			}()
			self.authToken = authToken
			completionHandler(nil)
		}
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
					guard let json = jsonObject as? Json else {
						throw Error.jsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					guard let userID = json["userId"] as? String else {
						throw Error.jsonMissingUserID(json: json)
					}
					let id = "user/\(userID)/\(readTagSuffix)"
					try _ = insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: backgroundQueueManagedObjectContext)
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error))
				}
			}
		}
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
					guard let json = jsonObject as? Json else {
						throw Error.jsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					guard let itemJsons = json["unreadcounts"] as? [Json] else {
						throw Error.jsonMissingUnreadCounts(json: json)
					}
					for itemJson in itemJsons {
						guard let itemID = itemJson["id"] as? String else {
							throw Error.itemJsonMissingID(itemJson: itemJson)
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
		}
		sessionTask.resume()
	}
	func updateTags(from data: Data, completionHandler: (ErrorProtocol?) -> Void) {
		backgroundQueueManagedObjectContext.perform {
			do {
				try _ = importItemsFromJsonData(data, type: Folder.self, elementName: "tags", managedObjectContext: (backgroundQueueManagedObjectContext)) { (tag, json) in
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
	func dataTaskForPushingTags(for items: Set<Item>, category: Folder, excluded: Bool, completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let urlPath: String = {
			let urlArguments: [String] = {
				assert(0 < items.count)
				let itemIDsComponents = items.map { "i=\($0.shortID)" }
				let command = excluded ? "r" : "a"
				let tag = category.tag()!
				let urlArguments = ["\(command)=\(tag)"] + itemIDsComponents
				return urlArguments
			}()
			let urlArgumentsJoined = urlArguments.joined(separator: "&")
			return "/reader/api/0/edit-tag?\(urlArgumentsJoined)"
		}()
		return self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: urlPath, httpMethod: "POST", completionHandler: completionHandler)
	}
	public func pushTags(completionHandler: (ErrorProtocol?) -> ()) {
		let context = backgroundQueueManagedObjectContext
		context.perform {
			let completionLock = ConditionLock()
			var errors = [ErrorProtocol]()
			let tasks: [URLSessionTask] = [true, false].flatMap { (excluded: Bool) -> [URLSessionTask] in
				return try! Folder.allWithItems(toBeExcluded: excluded, in: context).map { category in
					let items = category.items(toBeExcluded: excluded)
					let task = self.dataTaskForPushingTags(for: items, category: category, excluded: excluded) { data, httpResponse, error in
						completionLock.lock()
						defer { completionLock.unlock(withCondition: completionLock.condition - 1) }
						guard nil == error else {
							errors += [error!]
							return
						}
						context.perform {
							if (excluded) {
								category.itemsToBeExcluded.subtract(items)
							}
							else {
								category.itemsToBeIncluded.subtract(items)
							}
							try! context.save()
							assert(try! !Folder.allWithItems(toBeExcluded: excluded, in: context).contains(category))
						}
					}
					return task
				}
			}
			completionLock.lock()
			completionLock.unlock(withCondition: tasks.count)
			for task in tasks {
				task.resume()
			}
			DispatchQueue.global(attributes: .qosBackground).async {
				completionLock.lock(whenCondition: 0)
				defer { completionLock.unlock() }
				guard 0 == errors.count else {
					completionHandler(Error.pushTagsFailed(underlyingErrors: errors))
					return
				}
				completionHandler(nil)
			}
		}
		
	}
	public func pullTags(completionHandler: (ErrorProtocol?) -> Void) {
		let path = "/reader/api/0/tag/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withPath: path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let data = data!
			try! data.write(to: lastTagsFileURL, options: .dataWritingAtomic)
			self.updateTags(from: data, completionHandler: completionHandler)
		}
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
					guard let json = jsonObject as? Json else {
						throw Error.jsonObjectIsNotDictionary(jsonObject: jsonObject)
					}
					guard let streamprefsJson: AnyObject = json["streamprefs"] else {
						throw Error.jsonMissingStreamPrefs(json: json)
					}
					try Container.importStreamPreferencesJson(streamprefsJson, managedObjectContext: backgroundQueueManagedObjectContext)
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error))
				}
			}
		}
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
					try _ = importItemsFromJsonData(data, type: Subscription.self, elementName: "subscriptions", managedObjectContext: backgroundQueueManagedObjectContext) { (subscription, json) in
						try subscription.importFromJson(json)
					}
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					completionHandler($(error))
				}
			}
		}
		sessionTask.resume()
	}
	public func markAllAsRead(_ container: Container, completionHandler: (ErrorProtocol?) -> Void) {
		let relativeString: String = {
			let containerIDPercentEncoded = container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics())!
			let newestItemTimestampUsec = container.newestItemDate.timestampUsec
			return "/reader/api/0/mark-all-as-read?s=\(containerIDPercentEncoded)&ts=\(newestItemTimestampUsec)"
		}()
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: relativeString) { data, httpResponse, error in
			do {
				if let error = error {
					throw error
				}
				let data = data!
				guard let body = String(data: data, encoding: String.Encoding.utf8) else {
					throw Error.badResponseDataForMarkAsRead(data: data)
				}
				guard body == "OK" else {
					throw Error.unexpectedResponseTextForMarkAsRead(body: body as String)
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
		}
		sessionTask.resume()
	}
	// MARK: -
	public func streamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: Date, completionHandler: (continuation: String?, items: [Item]?, error: ErrorProtocol?) -> Void) {
		let relativeString: String = {
			let querySuffix = URLQuerySuffixFromComponents([String]() … {
				if let continuation = continuation {
					$0 += ["c=\($(continuation))"]
				}
				if let excludedCategory = excludedCategory {
					$0 += ["xt=\($(excludedCategory.streamID))"]
				}
				$0 += ["n=\(count)"]
			})
			let streamIDPercentEncoded = container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics())!
			return "/reader/api/0/stream/contents/\(streamIDPercentEncoded)\(querySuffix)"
		}()
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: relativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(continuation: nil, items: nil, error: error)
				return
			}
			let excludedCategoryObjectID = typedObjectID(for: excludedCategory)
			let containerObjectID = typedObjectID(for: container)
			let managedObjectContext = backgroundQueueManagedObjectContext
			managedObjectContext.perform {
				do {
					let container = containerObjectID.object(in: managedObjectContext)
					let excludedCategory = excludedCategoryObjectID?.object(in: managedObjectContext)
					let (continuation, items) = try continuationAndItemsImportedFromStreamData(data!, loadDate: loadDate, container: container, excludedCategory: excludedCategory, managedObjectContext: managedObjectContext)
					completionHandler(continuation: continuation, items: items, error: nil)
				} catch {
					completionHandler(continuation: nil, items: nil, error: $(error))
				}
			}
		}
		sessionTask.resume()
	}
}
