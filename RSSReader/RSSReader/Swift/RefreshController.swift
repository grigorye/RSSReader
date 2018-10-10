//
//  Commands.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.07.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Promises
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
		
		func completeWithError(_ error: Error) {
			switch error {
			case RSSSessionError.authenticationFailed(_):
				let adjustedError = AuthenticationFailed()
				self.refreshingSubscriptionsError = adjustedError
			default:
				self.refreshingSubscriptionsError = error
				#if false
				let title = NSLocalizedString("Refresh Failed", comment: "Title for alert on failed refresh")
				self.present(error, customTitle: title)
				#endif
			}
			complete(self.refreshingSubscriptionsError)
		}
		
		guard let rssSession = rssSession else {
			completeWithError(NotLoggedIn())
			return
		}
		
		let foldersController = self.foldersController
		
		refreshingSubscriptions = true
		Promise({
			return rssSession.authenticate()
		}).then({
			return foldersController.updateFolders(via: rssSession)
		}).always({
			self.refreshingSubscriptions = false
		}).then({
			complete(nil)
		}).catch({
			completeWithError($0)
			return
		})
	}
}

var refreshController = RefreshController()
