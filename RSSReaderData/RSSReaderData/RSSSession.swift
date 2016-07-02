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
	//
	func performPersistentDataUpdateCommand<T: PersistentDataUpdateCommand where T.ResultType == Void>(_ command: T, completionHandler: (ErrorProtocol?) -> Void) {
		command.taskForSession(self) { data, httpResponse, error in
			if let error = error {
				completionHandler(command.preprocessed(error))
				return
			}
			command.push(data!, through: { importResultIntoManagedObjectContext in
				backgroundQueueManagedObjectContext.perform {
					do {
						try importResultIntoManagedObjectContext(backgroundQueueManagedObjectContext)
						try backgroundQueueManagedObjectContext.save()
						completionHandler(nil)
					} catch {
						$(command)
						completionHandler($(error))
					}
				}
			})
		}.resume()
	}
	func performPersistentDataUpdateCommand<T: PersistentDataUpdateCommand>(_ command: T, completionHandler: (ErrorProtocol?, T.ResultType?) -> Void) {
		command.taskForSession(self) { data, httpResponse, error in
			if let error = error {
				completionHandler(command.preprocessed(error), nil)
				return
			}
			command.push(data!, through: { importResultIntoManagedObjectContext in
				backgroundQueueManagedObjectContext.perform {
					do {
						let result = try importResultIntoManagedObjectContext(backgroundQueueManagedObjectContext)
						try backgroundQueueManagedObjectContext.save()
						completionHandler(nil, result)
					} catch {
						$(command)
						completionHandler($(error), nil)
					}
				}
			})
		}.resume()
	}
	// MARK: -
	public func authenticate(_ completionHandler: (ErrorProtocol?) -> Void) {
		self.performPersistentDataUpdateCommand(Authenticate(loginAndPassword: loginAndPassword)) {
			error, authToken in
			guard nil != error else {
				completionHandler(error!)
				return
			}
			self.authToken = authToken
			completionHandler(nil)
		}
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
	public func streamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: Date, completionHandler: (ErrorProtocol?, (String?, [Item])?) -> Void) {
		self.performPersistentDataUpdateCommand(StreamContents(excludedCategory: excludedCategory, container: container, continuation: continuation, loadDate: loadDate), completionHandler: completionHandler)
	}
	/// MARK: -
	func pushTags(from context: NSManagedObjectContext, completionHandler: CommandCompletionHandler) {
		let dispatchGroup = DispatchGroup()
		var errors = [ErrorProtocol]()
		let completionQueue = DispatchQueue.global(attributes: .qosUserInteractive)
		for excluded in [true, false] {
			for category in try! Folder.allWithItems(toBeExcluded: excluded, in: context) {
				let items = category.items(toBeExcluded: excluded)
				dispatchGroup.enter()
				self.performPersistentDataUpdateCommand(PushTags(items: items, category: category, excluded: excluded)) {
					(error: ErrorProtocol?) -> Void in
					completionQueue.async {
						if let error = error {
							errors.append(error)
						}
						dispatchGroup.leave()
					}
				}
			}
		}
		DispatchQueue.global(attributes: .qosUtility).async {
			dispatchGroup.wait()
			if 0 != errors.count {
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
}
