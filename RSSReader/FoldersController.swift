//
//  FoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.05.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

protocol FoldersController {
	func updateAllAuthenticated(completionHandler: (NSError?) -> Void)
	func updateAll(completionHandler: (NSError?) -> Void)
}

extension AppDelegate: FoldersController {
	func updateAllAuthenticated(completionHandler: (NSError?) -> Void) {
		let rssSession = self.rssSession!
		rssSession.updateUserInfo { updateUserInfoError in dispatch_async(dispatch_get_main_queue()) {
			if let updateUserInfoError = updateUserInfoError {
				completionHandler(applicationError(.UserInfoRetrievalError, $(updateUserInfoError).$()))
				return
			}
			rssSession.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = updateTagsError {
					completionHandler(applicationError(.TagsUpdateError, $(updateTagsError).$()))
					return
				}
				rssSession.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateSubscriptionsError = updateSubscriptionsError {
						completionHandler(applicationError(.TagsUpdateError, $(updateSubscriptionsError).$()))
						return
					}
					rssSession.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = updateUnreadCountsError {
							completionHandler(applicationError(.TagsUpdateError, $(updateUnreadCountsError).$()))
							return
						}
						rssSession.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = updateStreamPreferencesError {
								completionHandler(applicationError(.StreamPreferencesUpdateError, $(updateStreamPreferencesError).$()))
								return
							}
							completionHandler(nil)
						}}
					}}
				}}
			}}
		}}
	}
	func updateAll(completionHandler: (NSError?) -> Void) {
		let rssSession = self.rssSession!
		let postAuthenticate = { () -> Void in
			self.updateAllAuthenticated(completionHandler)
		}
		if (rssSession.authToken == nil) {
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
