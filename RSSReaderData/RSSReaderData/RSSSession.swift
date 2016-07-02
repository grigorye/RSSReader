//
//  RSSSession.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import PromiseKit
import Result
import Foundation
import CoreData

let lastTagsFileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/lastTags")

var itemsAreSortedByLoadDate: Bool {
	return defaults.itemsAreSortedByLoadDate
}

public enum RSSSessionError: ErrorProtocol {
	case authenticationFailed(underlyingError: ErrorProtocol)
	case requestFailed(underlyingError: ErrorProtocol)
	case jsonObjectIsNotDictionary(jsonObject: AnyObject)
	case jsonMissingUserID(json: [String: AnyObject])
	case jsonMissingUnreadCounts(json: [String: AnyObject])
	case itemJsonMissingID(itemJson: [String: AnyObject])
	case jsonMissingStreamPrefs(json: [String: AnyObject])
	case unexpectedResponseTextForMarkAsRead(body: String)
	case badResponseDataForMarkAsRead(data: NSData)
	case pushTagsFailed(underlyingErrors: [ErrorProtocol])
	case importFailed(underlyingError: ErrorProtocol)
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
public typealias ResultCompletionHandler<ResultType, ErrorType: ErrorProtocol> = (Result<ResultType, ErrorType>) -> Void

extension RSSSession {
	public typealias CommandCompletionHandler<T> = ResultCompletionHandler<T, Error>
	// MARK: -
	func performPersistentDataUpdateCommand<T: PersistentDataUpdateCommand>(_ command: T, completionHandler: (Result<T.ResultType, Error>) -> Void) {
		command.taskForSession(self) { data, httpResponse, error in
			if let error = error {
				completionHandler(.Failure(command.preprocessedRequestError(error)))
				return
			}
			command.push(data!, through: { importResultIntoManagedObjectContext in
				backgroundQueueManagedObjectContext.perform {
					do {
						let result = try importResultIntoManagedObjectContext(backgroundQueueManagedObjectContext)
						try backgroundQueueManagedObjectContext.save()
						completionHandler(.Success(result))
					} catch {
						$(command)
						completionHandler(.Failure(.importFailed(underlyingError: $(error))))
					}
				}
			})
		}.resume()
	}
	func promise<T: PersistentDataUpdateCommand>(for command: T) -> Promise<T.ResultType> {
		return Promise { fulfill, reject in
			self.performPersistentDataUpdateCommand(command) { result in
				switch result {
				case .Success(let value):
					fulfill(value)
				case .Failure(let error):
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
		return self.promise(for: StreamContents(excludedCategory: excludedCategory, container: container, continuation: continuation, loadDate: loadDate))
	}
	/// MARK: -
	func pushTags(from context: NSManagedObjectContext, completionHandler: CommandCompletionHandler<Void>) {
		let dispatchGroup = DispatchGroup()
		var errors = [ErrorProtocol]()
		let completionQueue = DispatchQueue.global(attributes: .qosUserInteractive)
		for excluded in [true, false] {
			for category in try! Folder.allWithItems(toBeExcluded: excluded, in: context) {
				let items = category.items(toBeExcluded: excluded)
				dispatchGroup.enter()
				self.performPersistentDataUpdateCommand(PushTags(items: items, category: category, excluded: excluded)) {
					result -> Void in
					completionQueue.async {
						if case let .Failure(error) = result {
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
				completionHandler(.Failure(.pushTagsFailed(underlyingErrors: errors)))
				return
			}
			completionHandler(.Success())
		}
	}
	public func pushTags(completionHandler: CommandCompletionHandler<Void>) {
		let context = backgroundQueueManagedObjectContext
		context.perform {
			self.pushTags(from: context, completionHandler: completionHandler)
		}
	}
	public func pushTags() -> Promise<Void> {
		return Promise { fulfill, reject in
			self.pushTags { result in
				switch result {
				case .Success(let value):
					fulfill(value)
				case .Failure(let error):
					reject(error)
				}
			}
		}
	}
}
