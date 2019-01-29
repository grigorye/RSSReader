//
//  FoldersController.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Promises
import Foundation

@objc public enum FoldersUpdateState: Int {
	case unknown
	case ended
	case updatingUserInfo
	case pushingTags
	case pullingTags
	case updatingSubscriptions
	case updatingUnreadCounts
	case updatingStreamPreferences
	case prefetching
}

public protocol FoldersController : class {
	var foldersLastUpdateDate: Date? { get set }
	var foldersLastUpdateError: Error? { get set }
	var foldersUpdateState: FoldersUpdateState { get set }
}

extension TypedUserDefaults {
	@NSManaged var streamPrefetchingEnabled: Bool
}

public extension FoldersController {
	// swiftlint:disable:next function_body_length
	func updateFolders(via rssSession: RSSSession) -> Promise<Void> {
		precondition(rssSession.authenticated)
		return Promise({ () -> Promise<Void> in
			self.foldersLastUpdateError = nil
			self.foldersUpdateState = .updatingUserInfo
			return rssSession.updateUserInfo()
		}).then({ _ -> Promise<Void> in
			self.foldersUpdateState = .pushingTags
			return x$(rssSession.pushTags())
		}).then({ _ -> Promise<Void> in
			self.foldersUpdateState = .pullingTags
			return x$(rssSession.pullTags())
		}).then({ _ -> Promise<Void> in
			self.foldersUpdateState = .updatingSubscriptions
			return x$(rssSession.updateSubscriptions())
		}).then({ _ -> Promise<Void> in
			self.foldersUpdateState = .updatingUnreadCounts
			return x$(rssSession.updateUnreadCounts())
		}).then({ _ -> Promise<Void> in
			self.foldersUpdateState = .updatingStreamPreferences
			return x$(rssSession.updateStreamPreferences())
		}).then({ _ -> Promise<Void> in
			guard defaults.streamPrefetchingEnabled else {
				return Promise {}
			}
			self.foldersUpdateState = .prefetching
			return Promise { fulfill, reject in
				performBackgroundMOCTask { managedObjectContext in
					let container = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: managedObjectContext)!
					let containerLoadController = ContainerLoadController(session: rssSession, container: container, unreadOnly: true, forceReload: true)
					let loadCancellation = containerLoadController.loadMore { error in
						guard let error = error else {
							fulfill(())
							return
						}
						reject(error)
					}
					_ = x$(loadCancellation)
				}
			}
		}).then({
			x$(self.foldersLastUpdateDate = Date())
		}).recover({ (error) -> Void in
			x$(self.foldersLastUpdateError = error)
			throw x$(error)
		}).always({
			x$(self.foldersUpdateState = .ended)
		})
	}
}
