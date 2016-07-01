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

extension RSSSession {
	// MARK: -
	public typealias CommandCompletionHandler = (ErrorProtocol?) -> Void
	func performPersistentDataUpdateCommand(_ command: PersistentDataUpdateCommand, completionHandler: CommandCompletionHandler) {
		self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: command.URLRequestRelativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(command.preprocessed(error))
				return
			}
			backgroundQueueManagedObjectContext.perform {
				do {
					try command.importResult(data!, into: backgroundQueueManagedObjectContext)
					try backgroundQueueManagedObjectContext.save()
					completionHandler(nil)
				} catch {
					$(command)
					completionHandler($(error))
				}
			}
		}.resume()
	}
	// MARK: -
	public func authenticate(_ completionHandler: (ErrorProtocol?) -> Void) {
		self.dataTaskForAuthentication { data, httpResponse, error in
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
			do {
				let authToken = try authTokenImportedFromJsonData(data!)
				self.authToken = authToken
				completionHandler(nil)
			}
			catch {
				completionHandler($(error))
			}
		}.resume()
	}
	func reauthenticate(completionHandler: (ErrorProtocol?) -> Void) {
		authenticate(completionHandler)
	}
	/// MARK: -
	public func updateUserInfo(completionHandler: CommandCompletionHandler) {
		self.performPersistentDataUpdateCommand(UpdateUserInfo(), completionHandler: completionHandler)
	}
	public func updateUnreadCounts(completionHandler: CommandCompletionHandler) {
		self.performPersistentDataUpdateCommand(UpdateUnreadCounts(), completionHandler: completionHandler)
	}
	public func pullTags(completionHandler: CommandCompletionHandler) {
		self.performPersistentDataUpdateCommand(PullTags(), completionHandler: completionHandler)
	}
	public func updateStreamPreferences(completionHandler: (ErrorProtocol?) -> Void) {
		self.performPersistentDataUpdateCommand(UpdateStreamPreferences(), completionHandler: completionHandler)
	}
	public func updateSubscriptions(completionHandler: CommandCompletionHandler) {
		self.performPersistentDataUpdateCommand(UpdateSubscriptions(), completionHandler: completionHandler)
	}
	public func markAllAsRead(_ container: Container, completionHandler: CommandCompletionHandler) {
		self.performPersistentDataUpdateCommand(MarkAllAsRead(container: container), completionHandler: completionHandler)
	}
	/// MARK: -
	func pushTags(from context: NSManagedObjectContext, completionHandler: CommandCompletionHandler) {
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
	public func pushTags(completionHandler: (ErrorProtocol?) -> ()) {
		let context = backgroundQueueManagedObjectContext
		context.perform {
			self.pushTags(from: context, completionHandler: completionHandler)
		}
	}
	public func streamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: Date, completionHandler: (continuation: String?, items: [Item]?, error: ErrorProtocol?) -> Void) {
		self.dataTaskForStreamContents(container, excludedCategory: excludedCategory, continuation: continuation, count: count, loadDate: loadDate) { data, httpResponse, error in
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
		}.resume()
	}
}
