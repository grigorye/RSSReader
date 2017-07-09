//
//  Commands.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.07.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import RSSReaderData
import PromiseKit
import Foundation

func rootFolder() -> Folder? {
	return x$(Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext))
}

class RefreshController: NSObject {
	
	@objc dynamic var refreshingSubscriptions: Bool = false
	var refreshingSubscriptionsError: Error?
	
	func refreshSubscriptions(complete: @escaping (Error?) -> ()) {
		assert(!refreshingSubscriptions)
		refreshingSubscriptions = true
		let rssAccount = self.rssAccount
		let foldersController = self.foldersController
		firstly { () -> Promise<Void> in
			guard nil != rssSession else {
				throw NotLoggedIn()
			}
			return Promise(value: ())
		}.then { (_) -> Promise<Void> in
			return rssAccount.authenticate()
		}.then { (_) -> Promise<Void> in
			return foldersController.updateFolders()
		}.then { (_) -> Void in
			self.refreshingSubscriptions = false
		}.catch { updateError in
			switch updateError {
			case RSSSessionError.authenticationFailed(_):
				let adjustedError = AuthenticationFailed()
				self.refreshingSubscriptionsError = adjustedError
			default:
				self.refreshingSubscriptionsError = updateError
				#if false
				let title = NSLocalizedString("Refresh Failed", comment: "Title for alert on failed refresh")
				self.present(error, customTitle: title)
				#endif
			}
			return
		}
	}
	
}

var refreshController = RefreshController()
