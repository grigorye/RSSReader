//
//  FoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

enum FoldersUpdateState: String {
	case Unknown = "Unknown"
	case Completed = "Completed"
	case Authenticating = "Authenticating..."
	case UpdatingUserInfo = "Updating user info..."
	case UpdatingTags = "Updating tags..."
	case UpdatingSubscriptions = "Updating subscriptions..."
	case UpdatingUnreadCounts = "Updating unread counts..."
	case UpdatingStreamPreferences = "Updating stream preferences..."
}

protocol FoldersController {
	func updateFoldersAuthenticated(completionHandler: (NSError?) -> Void)
	func updateFolders(completionHandler: (NSError?) -> Void)
	var foldersLastUpdateError: NSError? { get }
	var foldersLastUpdateDate: NSDate? { get }
	var foldersUpdateState: FoldersUpdateState { get }
	var foldersUpdateStateRaw: String { get }
}

extension AppDelegate: FoldersController {
	final var foldersLastUpdateDate: NSDate? {
		get {
			return defaults.foldersLastUpdateDate
		}
		set {
			defaults.foldersLastUpdateDate = newValue
		}
	}
	final var foldersLastUpdateError: NSError? {
		get {
			if let data = defaults.foldersLastUpdateErrorEncoded {
				return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSError?
			}
			else {
				return nil
			}
		}
		set {
			defaults.foldersLastUpdateErrorEncoded = {
				if let newValue = newValue {
					return NSKeyedArchiver.archivedDataWithRootObject(newValue)
				}
				else {
					return nil
				}
			}()
		}
	}
	final func updateFoldersAuthenticated(completionHandler: (NSError?) -> Void) {
		let rssSession = self.rssSession!
		foldersUpdateState = .UpdatingUserInfo
		let errorCompletionHandler = { (error: NSError) -> Void in
			self.foldersLastUpdateError = error
			self.foldersLastUpdateDate = NSDate()
			self.foldersUpdateState = .Completed
			completionHandler(error)
		}
		let successCompletionHandler: () -> Void = {
			self.foldersLastUpdateDate = NSDate()
			self.foldersUpdateState = .Completed
			completionHandler(nil)
		}
		self.foldersLastUpdateError = nil
		rssSession.updateUserInfo { updateUserInfoError in dispatch_async(dispatch_get_main_queue()) {
			if let updateUserInfoError = updateUserInfoError {
				errorCompletionHandler(applicationError(.UserInfoRetrievalError, $(updateUserInfoError).$()))
				return
			}
			self.foldersUpdateState = .UpdatingTags
			rssSession.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = updateTagsError {
					errorCompletionHandler(applicationError(.TagsUpdateError, $(updateTagsError).$()))
					return
				}
				self.foldersUpdateState = .UpdatingSubscriptions
				rssSession.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateSubscriptionsError = updateSubscriptionsError {
						errorCompletionHandler(applicationError(.TagsUpdateError, $(updateSubscriptionsError).$()))
						return
					}
					self.foldersUpdateState = .UpdatingUnreadCounts
					rssSession.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = updateUnreadCountsError {
							errorCompletionHandler(applicationError(.TagsUpdateError, $(updateUnreadCountsError).$()))
							return
						}
						self.foldersUpdateState = .UpdatingStreamPreferences
						rssSession.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = updateStreamPreferencesError {
								errorCompletionHandler(applicationError(.StreamPreferencesUpdateError, $(updateStreamPreferencesError).$()))
								return
							}
							successCompletionHandler()
						}}
					}}
				}}
			}}
		}}
	}
	final func updateFolders(completionHandler: (NSError?) -> Void) {
		let rssSession = self.rssSession!
		let postAuthenticate = { () -> Void in
			self.updateFoldersAuthenticated(completionHandler)
		}
		if (rssSession.authToken == nil) {
			self.foldersUpdateState = .Authenticating
			rssSession.authenticate { error in dispatch_async(dispatch_get_main_queue()) {
				if let authenticationError = error {
					completionHandler(authenticationError)
				}
				else {
					postAuthenticate()
				}
			}}
		}
		else {
			postAuthenticate()
		}
	}
}
