//
//  GlobalFoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation

extension TypedUserDefaults {
	@NSManaged var foldersLastUpdateDate: Date!
	@NSManaged var foldersLastUpdateErrorEncoded: Data?
}

class GlobalFoldersController : NSObject, FoldersController {

	final var foldersLastUpdateDate: Date? {
		get {
			return defaults.foldersLastUpdateDate
		}
		set {
			defaults.foldersLastUpdateDate = newValue
		}
	}
	
	final var foldersLastUpdateError: Error? {
		get {
			return UserDefaults.standard.decodeInGetter()
		}
		set {
			UserDefaults.standard.encodeInSetter(newValue as NSError?)
		}
	}
	
	@objc dynamic var foldersUpdateState: FoldersUpdateState = .unknown
}
