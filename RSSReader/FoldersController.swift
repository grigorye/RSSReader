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
	func updateFoldersAuthenticated(completionHandler: (ErrorType?) -> Void)
	func updateFolders(completionHandler: (ErrorType?) -> Void)
	var foldersLastUpdateError: ErrorType? { get }
	var foldersLastUpdateDate: NSDate? { get }
	var foldersUpdateState: FoldersUpdateState { get }
	var foldersUpdateStateRaw: String { get }
}

extension AppDelegate: FoldersController {
	enum Error: ErrorType {
		case UserInfoRetrieval(underlyingError: ErrorType)
		case TagsUpdate(underlyingError: ErrorType)
		case SubscriptionsUpdate(underlyingError: ErrorType)
		case DataDoesNotMatchTextEncoding
		case UnreadCountsUpdate(underlyingError: ErrorType)
		case StreamPreferencesUpdate(underlyingError: ErrorType)
	}
	final var foldersLastUpdateDate: NSDate? {
		get {
			return defaults.foldersLastUpdateDate
		}
		set {
			defaults.foldersLastUpdateDate = newValue
		}
	}
	final var foldersLastUpdateError: ErrorType? {
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
				if let _ = newValue {
					return nil // NSKeyedArchiver.archivedDataWithRootObject(newValue)
				}
				else {
					return nil
				}
			}()
		}
	}
	final func updateFoldersAuthenticated(completionHandler: (ErrorType?) -> Void) {
		let rssSession = self.rssSession!
		foldersUpdateState = .UpdatingUserInfo
		let errorCompletionHandler = { (error: ErrorType) -> Void in
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
				errorCompletionHandler(Error.UserInfoRetrieval(underlyingError: $(updateUserInfoError).$()))
				return
			}
			self.foldersUpdateState = .UpdatingTags
			rssSession.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = updateTagsError {
					errorCompletionHandler(Error.TagsUpdate(underlyingError: $(updateTagsError).$()))
					return
				}
				self.foldersUpdateState = .UpdatingSubscriptions
				rssSession.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateSubscriptionsError = updateSubscriptionsError {
						errorCompletionHandler(Error.SubscriptionsUpdate(underlyingError: $(updateSubscriptionsError).$()))
						return
					}
					self.foldersUpdateState = .UpdatingUnreadCounts
					rssSession.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = updateUnreadCountsError {
							errorCompletionHandler(Error.TagsUpdate(underlyingError: $(updateUnreadCountsError).$()))
							return
						}
						self.foldersUpdateState = .UpdatingStreamPreferences
						rssSession.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = updateStreamPreferencesError {
								errorCompletionHandler(Error.StreamPreferencesUpdate(underlyingError: $(updateStreamPreferencesError).$()))
								return
							}
							successCompletionHandler()
						}}
					}}
				}}
			}}
		}}
	}
	final func updateFolders(completionHandler: (ErrorType?) -> Void) {
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
