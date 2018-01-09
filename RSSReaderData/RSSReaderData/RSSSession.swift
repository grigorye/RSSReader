//
//  RSSSession.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import class GEFoundation.ProgressEnabledURLSessionTaskGenerator
import PromiseKit
import Foundation
import CoreData

public enum RSSSessionError: Error {
	case unused
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

extension ProgressEnabledURLSessionTaskGenerator: RSSSessionDataTaskGenerator {
}

public class RSSSession: NSObject {
	
	let inoreaderAppID = "1000001375"
	let inoreaderAppKey = "r3O8gX6FPdFaOXE3x4HypYHO2LTCNuDS"
	let loginAndPassword: LoginAndPassword
	
	let dataTaskGenerator: RSSSessionDataTaskGenerator

	public var authenticationState: AuthenticationState = .nonStarted {
		willSet {
			willChangeValue(for: \.authenticationState$)
		}
		didSet {
			didChangeValue(for: \.authenticationState$)
		}
	}
	@objc public var authenticationState$: UnusedKVOValue {
		return nil
	}
	
	var authToken: String! {
		get {
			return defaults.authToken
		}
		set {
			defaults.authToken = newValue
		}
	}

	public init(loginAndPassword: LoginAndPassword, dataTaskGenerator: RSSSessionDataTaskGenerator = progressEnabledURLSessionTaskGenerator) {
		_ = RSSSession.initializeOnce
		precondition(loginAndPassword.isValid())
		self.dataTaskGenerator = dataTaskGenerator
		self.loginAndPassword = loginAndPassword
		super.init()
	}
}

extension TypedUserDefaults {
	@NSManaged var authToken: String?
}

public extension RSSSession {
	
	var authenticated: Bool {
		return nil != authToken
	}
	
	static func setErrorUserInfoValueProvider() {
		let errorDomain = (RSSSessionError.unused as NSError).domain
		NSError.setUserInfoValueProvider(forDomain: x$(errorDomain)) { error, key in
			switch error {
			case RSSSessionError.requestFailed(let underlyingError):
				return (underlyingError as NSError).userInfo[key]
			case RSSSessionError.authenticationFailed(_):
				if key == NSLocalizedDescriptionKey {
					return NSLocalizedString("Authentication Failed", comment: "Error description for authentication failure")
				}
				return nil
			default:
				return nil
			}
		}
	}
	
	static fileprivate let initializeOnce: Ignored = {
		setErrorUserInfoValueProvider()
		return Ignored()
	}()
}

extension TypedUserDefaults {
	@NSManaged var obtainPermanentObjectIDsForRSSData: Bool
	@NSManaged var resetBackgroundQueueMOCAfterSavingRSSData: Bool
}

extension RSSSession {
	public typealias CommandCompletionHandler<ResultType> = (Result<ResultType>) -> Void
	// MARK: -
	func performPersistentDataUpdateCommand<T: PersistentDataUpdateCommand>(_ command: T, completionHandler: @escaping CommandCompletionHandler<T.ResultType>) {
		x$(command as AbstractPersistentDataUpdateCommand)
		let task = command.taskForSession(self) { data, httpResponse, error in
			if let error = error {
				completionHandler(.rejected(command.preprocessedRequestError(error)))
				return
			}
			command.push(data!, through: { importResultIntoManagedObjectContext in
				performBackgroundMOCTask { managedObjectContext in
					do {
						let result = try importResultIntoManagedObjectContext(managedObjectContext)
						if defaults.obtainPermanentObjectIDsForRSSData {
							let insertedObjects = managedObjectContext.insertedObjects
							if 0 < insertedObjects.count {
								try managedObjectContext.obtainPermanentIDs(for: Array(insertedObjects))
							}
						}
						if managedObjectContext.hasChanges {
							try managedObjectContext.save()
						}
						completionHandler(.fulfilled(result))
						if defaults.resetBackgroundQueueMOCAfterSavingRSSData {
							managedObjectContext.reset()
						}
					} catch {
						completionHandler(.rejected(RSSSessionError.importFailed(underlyingError: x$(error), command: x$(command))))
					}
				}
			})
		}
		task.resume()
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
				self.performPersistentDataUpdateCommand(PushTags(items: items, category: category, excluded: excluded)) { result -> Void in
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
			completionHandler(.fulfilled(()))
		}
	}
	public func pushTags(completionHandler: @escaping CommandCompletionHandler<Void>) {
		performBackgroundMOCTask { managedObjectContext in
			self.pushTags(from: managedObjectContext, completionHandler: completionHandler)
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

extension RSSSession /** Authentication */ {
	
	public enum AuthenticationState {
		
		case nonStarted
		case inProgress
		case succeeded
		case failed(error: Error)
	}
	
	public func authenticate() -> Promise<Void> {
		
		guard !authenticated else {
			return Promise()
		}
		
		if case .inProgress = self.authenticationState {
			assert(false)
			fatalError()
		}
		
		authenticationState = .inProgress
		
		let commandPromise = self.promise(for: Authenticate(loginAndPassword: x$(loginAndPassword)))
		
		return commandPromise.then(execute: {
			self.authToken = $0
			self.authenticationState = .succeeded
			return Promise()
		}).recover(execute: { authenticationError -> Void in
			self.authenticationState = .failed(error: authenticationError)
			throw x$(authenticationError)
		})
	}
	
	func reauthenticate() -> Promise<Void> {
		return authenticate()
	}
}
