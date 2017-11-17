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

func fakeRootFolder() -> Folder? {
	return x$(Folder.folderWithTagSuffix(fakeRootTagSuffix, managedObjectContext: mainQueueManagedObjectContext))
}

func fakeRootFolderInsertedAsNecessary() -> Folder {
	if let fakeRootFolder = RSSReader.fakeRootFolder() {
		return fakeRootFolder
	}
	let fakeRootFolder = Folder(context: mainQueueManagedObjectContext) … {
		$0.streamID = fakeRootTagSuffix
	}
	try! mainQueueManagedObjectContext.save()
	return fakeRootFolder
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
		}.always {
			self.refreshingSubscriptions = false
		}.then {
			complete(nil)
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
			complete(self.refreshingSubscriptionsError)
			return
		}
	}
	
}

var refreshController = RefreshController()
