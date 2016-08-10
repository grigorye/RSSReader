//
//  FoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import PromiseKit
import Foundation

enum FoldersUpdateState: Int {
	case unknown
	case completed
	case authenticating
	case updatingUserInfo
	case pushingTags
	case pullingTags
	case updatingSubscriptions
	case updatingUnreadCounts
	case updatingStreamPreferences
	case prefetching
}

extension FoldersUpdateState: CustomStringConvertible {
	var description: String {
		switch self {
		case .unknown:
			return NSLocalizedString("Unknown", comment: "Folders Update State")
		case .authenticating:
			return NSLocalizedString("Authenticating", comment: "Folders Update State")
		case .updatingUserInfo:
			return NSLocalizedString("Updating User Info", comment: "Folders Update State")
		case .pushingTags:
			return NSLocalizedString("Pushing Tags", comment: "Folders Update State")
		case .pullingTags:
			return NSLocalizedString("Pulling Tags", comment: "Folders Update State")
		case .updatingSubscriptions:
			return NSLocalizedString("Updating Subscriptions", comment: "Folders Update State")
		case .updatingUnreadCounts:
			return NSLocalizedString("Updating Unread Counts", comment: "Folders Update State")
		case .updatingStreamPreferences:
			return NSLocalizedString("Updating Folder List", comment: "Folders Update State")
		case .prefetching:
			return NSLocalizedString("Prefetching", comment: "Folders Update State")
		case .completed:
			return NSLocalizedString("Completed", comment: "Folders Update State")
		}
	}
}

enum FoldersControllerError: ErrorProtocol {
	case userInfoRetrieval(underlyingError: ErrorProtocol)
	case pushTags(underlyingError: ErrorProtocol)
	case pullTags(underlyingError: ErrorProtocol)
	case subscriptionsUpdate(underlyingError: ErrorProtocol)
	case dataDoesNotMatchTextEncoding
	case unreadCountsUpdate(underlyingError: ErrorProtocol)
	case streamPreferencesUpdate(underlyingError: ErrorProtocol)
}

@objc protocol FoldersController {
	var foldersLastUpdateDate: Date? { get set }
	var foldersLastUpdateErrorRaw: NSError? { get set }
	var foldersUpdateStateRaw: Int { get set }
}

extension FoldersController {
	final var foldersUpdateState: FoldersUpdateState {
		set {
			foldersUpdateStateRaw = newValue.rawValue
		}
		get {
			return FoldersUpdateState(rawValue: foldersUpdateStateRaw)!
		}
	}
	final var foldersLastUpdateError: ErrorProtocol? {
		set {
			foldersLastUpdateErrorRaw = NSError(domain: "", code: 1, userInfo: ["swiftError": "\(newValue)"])
		}
		get {
			return nil
		}
	}
	typealias Error = FoldersControllerError
	final func updateFoldersAuthenticated() -> Promise<Void> {
		let rssSession = RSSReader.rssSession!
		let promise: Promise<Void> = firstly {
			self.foldersLastUpdateError = nil
			self.foldersUpdateState = .updatingUserInfo
			return rssSession.updateUserInfo()
		}.then {
			self.foldersUpdateState = .pushingTags
			return rssSession.pushTags()
		}.then {
			self.foldersUpdateState = .pullingTags
			return rssSession.pullTags()
		}.then {
			self.foldersUpdateState = .updatingSubscriptions
			return rssSession.updateSubscriptions()
		}.then {
			self.foldersUpdateState = .updatingUnreadCounts
			return rssSession.updateUnreadCounts()
		}.then {
			self.foldersUpdateState = .updatingStreamPreferences
			return rssSession.updateStreamPreferences()
		}.then {
			self.foldersUpdateState = .prefetching
			let context = backgroundQueueManagedObjectContext
			return Promise { fulfill, reject in
				context.perform {
					let containerLoadController = ContainerLoadController()…{
						$0.container = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: context)
						$0.unreadOnly = true
					}
					containerLoadController.loadMore { error in
						guard let error = error else {
							fulfill()
							return
						}
						reject(error)
					}
				}
			}
		}.always {
			self.foldersUpdateState = .completed
			self.foldersLastUpdateDate = Date()
		}.recover { error -> Void in
			self.foldersLastUpdateError = error
			throw $(error)
		}
		return promise
	}
}
