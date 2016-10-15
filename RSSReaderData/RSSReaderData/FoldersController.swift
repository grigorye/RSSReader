//
//  FoldersController.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import PromiseKit
import Foundation

@objc public enum FoldersUpdateState: Int {
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
	public var description: String {
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

public protocol FoldersController : class {
	var foldersLastUpdateDate: Date? { get set }
	var foldersLastUpdateError: Error? { get set }
	var foldersUpdateState: FoldersUpdateState { get set }
	var rssSession: RSSSession { get }
}

public extension FoldersController {
	public final func updateFoldersAuthenticated() -> Promise<Void> {
		let rssSession = self.rssSession
		return firstly {
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
					let container = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: context)!
					let containerLoadController = ContainerLoadController(session: rssSession, container: container, unreadOnly: true)
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
	}
}
