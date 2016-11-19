//
//  RSSSession.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import PromiseKit
import Foundation
import CoreData

let lastTagsFileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/lastTags")

public enum RSSSessionError: Error {
	case authenticationFailed(underlyingError: Error)
	case requestFailed(underlyingError: Error)
	case jsonObjectIsNotDictionary(jsonObject: Any)
	case jsonMissingUserID(json: [String: AnyObject])
	case jsonMissingUnreadCounts(json: [String: AnyObject])
	case itemJsonMissingID(itemJson: [String: AnyObject])
	case jsonMissingStreamPrefs(json: [String: AnyObject])
	case unexpectedResponseTextForMarkAsRead(body: String)
	case badResponseDataForMarkAsRead(data: Data)
	case pushTagsFailed(underlyingErrors: [Error])
	case importFailed(underlyingError: Error, command: AbstractPersistentDataUpdateCommand)
}

public class RSSSession: NSObject {
	let inoreaderAppID = "1000001375"
	let inoreaderAppKey = "r3O8gX6FPdFaOXE3x4HypYHO2LTCNuDS"
	let loginAndPassword: LoginAndPassword
	public init(loginAndPassword: LoginAndPassword) {
		precondition(loginAndPassword.isValid())
		self.loginAndPassword = loginAndPassword
	}
}

extension KVOCompliantUserDefaults {
	@NSManaged var authToken: String?
}

public extension RSSSession {
	var authToken: String! {
		get {
			return defaults.authToken
		}
		set {
			defaults.authToken = newValue
		}
	}
	var authenticated: Bool {
		return nil != authToken
	}
}

extension KVOCompliantUserDefaults {
	@NSManaged var obtainPermanentObjectIDsForRSSData: Bool
	@NSManaged var resetBackgroundQueueMOCAfterSavingRSSData: Bool
}

extension RSSSession {
	public typealias CommandCompletionHandler<ResultType> = (Result<ResultType>) -> Void
	// MARK: -
	func performPersistentDataUpdateCommand<T: PersistentDataUpdateCommand>(_ command: T, completionHandler: @escaping CommandCompletionHandler<T.ResultType>) {
		$(command as AbstractPersistentDataUpdateCommand)
		command.taskForSession(self) { data, httpResponse, error in
			if let error = error {
				completionHandler(.rejected(command.preprocessedRequestError(error)))
				return
			}
			command.push(data!, through: { importResultIntoManagedObjectContext in
				backgroundQueueManagedObjectContext.perform {
					do {
						let result = try importResultIntoManagedObjectContext(backgroundQueueManagedObjectContext)
						if defaults.obtainPermanentObjectIDsForRSSData {
							let insertedObjects = backgroundQueueManagedObjectContext.insertedObjects
							if 0 < insertedObjects.count {
								try backgroundQueueManagedObjectContext.obtainPermanentIDs(for: Array(insertedObjects))
							}
						}
						try backgroundQueueManagedObjectContext.save()
						completionHandler(.fulfilled(result))
						if defaults.resetBackgroundQueueMOCAfterSavingRSSData {
							backgroundQueueManagedObjectContext.reset()
						}
					} catch {
						completionHandler(.rejected(RSSSessionError.importFailed(underlyingError: $(error), command: $(command))))
					}
				}
			})
		}.resume()
	}
	func promise<T: PersistentDataUpdateCommand>(for command: T) -> Promise<T.ResultType> {
		return Promise { fulfill, reject in
			self.performPersistentDataUpdateCommand(command) { result in
				switch result {
				case .fulfilled(let value):
					fulfill(value)
				case .rejected(let error):
					reject(error)
				}
			}
		}
	}
	// MARK: -
	public func authenticate() -> Promise<Void> {
		return self.promise(for: Authenticate(loginAndPassword: loginAndPassword)).then {
			authToken in
			self.authToken = authToken
		}
	}
	func reauthenticate() -> Promise<Void> {
		return authenticate()
	}
	/// MARK: -
	public func updateUserInfo() -> Promise<Void> {
		return self.promise(for: UpdateUserInfo())
	}
	public func updateUnreadCounts() -> Promise<Void> {
		return self.promise(for: UpdateUnreadCounts())
	}
	public func pullTags() -> Promise<Void> {
		return self.promise(for: PullTags())
	}
	public func updateStreamPreferences() -> Promise<Void> {
		return self.promise(for: UpdateStreamPreferences())
	}
	public func updateSubscriptions() -> Promise<Void> {
		return self.promise(for: UpdateSubscriptions())
	}
	public func markAllAsRead(_ container: Container) -> Promise<Void> {
		return self.promise(for: MarkAllAsRead(container: container))
	}
	public func streamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: Date) -> Promise<StreamContents.ResultType> {
		return self.promise(for: StreamContents(excludedCategory: excludedCategory, container: container, continuation: continuation, count: count, loadDate: loadDate))
	}
	/// MARK: -
	func pushTags(from context: NSManagedObjectContext, completionHandler: @escaping CommandCompletionHandler<Void>) {
		let dispatchGroup = DispatchGroup()
		var errors = [Error]()
		let completionQueue = DispatchQueue.global(qos: .userInteractive)
		for excluded in [true, false] {
			for category in try! Folder.allWithItems(toBeExcluded: excluded, in: context) {
				let items = category.items(toBeExcluded: excluded)
				dispatchGroup.enter()
				self.performPersistentDataUpdateCommand(PushTags(items: items, category: category, excluded: excluded)) {
					result -> Void in
					completionQueue.async {
						if case let .rejected(error) = result {
							errors.append(error)
						}
						dispatchGroup.leave()
					}
				}
			}
		}
		DispatchQueue.global(qos: .utility).async {
			dispatchGroup.wait()
			if 0 != errors.count {
				completionHandler(.rejected(RSSSessionError.pushTagsFailed(underlyingErrors: errors)))
				return
			}
			completionHandler(.fulfilled())
		}
	}
	public func pushTags(completionHandler: @escaping CommandCompletionHandler<Void>) {
		let context = backgroundQueueManagedObjectContext
		context.perform {
			self.pushTags(from: context, completionHandler: completionHandler)
		}
	}
	public func pushTags() -> Promise<Void> {
		return Promise { fulfill, reject in
			self.pushTags { result in
				switch result {
				case .fulfilled(let value):
					fulfill(value)
				case .rejected(let error):
					reject(error)
				}
			}
		}
	}
}
