//
//  RSSSession.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
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
	public var authToken: String! {
		get {
			return defaults.authToken
		}
		set {
			defaults.authToken = newValue
		}
	}
}
public typealias ResultCompletionHandler<ResultType, ErrorType: ErrorProtocol> = (Result<ResultType, ErrorType>) -> Void

extension RSSSession {
	public typealias CommandCompletionHandler<T> = ResultCompletionHandler<T, Error>
	// MARK: -
	//
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
	// MARK: -
	public func authenticate(_ completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(Authenticate(loginAndPassword: loginAndPassword)) {
			result in
			guard case let .Success(authToken) = result else {
				completionHandler(.Failure(result.error!))
				return
			}
			self.authToken = authToken
			completionHandler(.Success())
		}
	}
	func reauthenticate(completionHandler: CommandCompletionHandler<Void>) {
		authenticate(completionHandler)
	}
	/// MARK: -
	public func updateUserInfo(completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(UpdateUserInfo(), completionHandler: completionHandler)
	}
	public func updateUnreadCounts(completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(UpdateUnreadCounts(), completionHandler: completionHandler)
	}
	public func pullTags(completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(PullTags(), completionHandler: completionHandler)
	}
	public func updateStreamPreferences(completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(UpdateStreamPreferences(), completionHandler: completionHandler)
	}
	public func updateSubscriptions(completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(UpdateSubscriptions(), completionHandler: completionHandler)
	}
	public func markAllAsRead(_ container: Container, completionHandler: CommandCompletionHandler<Void>) {
		self.performPersistentDataUpdateCommand(MarkAllAsRead(container: container), completionHandler: completionHandler)
	}
	public func streamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int = 20, loadDate: Date, completionHandler: CommandCompletionHandler<StreamContents.ResultType>) {
		self.performPersistentDataUpdateCommand(StreamContents(excludedCategory: excludedCategory, container: container, continuation: continuation, loadDate: loadDate), completionHandler: completionHandler)
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
}
