//
//  FoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import Foundation

enum FoldersUpdateState: Int {
	case Unknown
	case Completed
	case Authenticating
	case UpdatingUserInfo
	case UpdatingTags
	case UpdatingSubscriptions
	case UpdatingUnreadCounts
	case UpdatingStreamPreferences
}

extension FoldersUpdateState: CustomStringConvertible {
	var description: String {
		switch self {
		case .Unknown:
			return NSLocalizedString("Unknown", comment: "Folders Update State")
		case .Authenticating:
			return NSLocalizedString("Authenticating", comment: "Folders Update State")
		case .UpdatingUserInfo:
			return NSLocalizedString("Updating User Info", comment: "Folders Update State")
		case .UpdatingTags:
			return NSLocalizedString("Updating Tags", comment: "Folders Update State")
		case .UpdatingSubscriptions:
			return NSLocalizedString("Updating Subscriptions", comment: "Folders Update State")
		case .UpdatingUnreadCounts:
			return NSLocalizedString("Updating Unread Counts", comment: "Folders Update State")
		case .UpdatingStreamPreferences:
			return NSLocalizedString("Updating Unread Counts", comment: "Folders Update State")
		case .Completed:
			return NSLocalizedString("Completed", comment: "Folders Update State")
		}
	}
}

enum FoldersControllerError: ErrorType {
	case UserInfoRetrieval(underlyingError: ErrorType)
	case TagsUpdate(underlyingError: ErrorType)
	case SubscriptionsUpdate(underlyingError: ErrorType)
	case DataDoesNotMatchTextEncoding
	case UnreadCountsUpdate(underlyingError: ErrorType)
	case StreamPreferencesUpdate(underlyingError: ErrorType)
}

@objc protocol FoldersController {
#if false
	func updateFoldersAuthenticated(completionHandler: (ErrorType?) -> Void)
	func updateFolders(completionHandler: (ErrorType?) -> Void)
#endif
	var rssSession: RSSSession? { get }
	var foldersLastUpdateDate: NSDate? { get set }
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
	final var foldersLastUpdateError: ErrorType? {
		set {
			foldersLastUpdateErrorRaw = NSError(domain: "", code: 1, userInfo: ["swiftError": "\(newValue)"])
		}
		get {
			return nil
		}
	}
	typealias Error = FoldersControllerError
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
				errorCompletionHandler(Error.UserInfoRetrieval(underlyingError: $(updateUserInfoError)))
				return
			}
			self.foldersUpdateState = .UpdatingTags
			rssSession.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = updateTagsError {
					errorCompletionHandler(Error.TagsUpdate(underlyingError: $(updateTagsError)))
					return
				}
				self.foldersUpdateState = .UpdatingSubscriptions
				rssSession.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateSubscriptionsError = updateSubscriptionsError {
						errorCompletionHandler(Error.SubscriptionsUpdate(underlyingError: $(updateSubscriptionsError)))
						return
					}
					self.foldersUpdateState = .UpdatingUnreadCounts
					rssSession.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = updateUnreadCountsError {
							errorCompletionHandler(Error.TagsUpdate(underlyingError: $(updateUnreadCountsError)))
							return
						}
						self.foldersUpdateState = .UpdatingStreamPreferences
						rssSession.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = updateStreamPreferencesError {
								errorCompletionHandler(Error.StreamPreferencesUpdate(underlyingError: $(updateStreamPreferencesError)))
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
					self.foldersUpdateState = .Completed
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
