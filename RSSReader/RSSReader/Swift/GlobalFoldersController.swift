//
//  GlobalFoldersController.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import Foundation

extension KVOCompliantUserDefaults {
	@NSManaged var foldersLastUpdateDate: Date!
	@NSManaged var foldersLastUpdateErrorEncoded: Data?
}

class GlobalFoldersController : NSObject, FoldersController {

	var rssSession: RSSSession {
		return RSSReader.rssSession!
	}

	final var foldersLastUpdateDate: Date? {
		get {
			return defaults.foldersLastUpdateDate
		}
		set {
			defaults.foldersLastUpdateDate = newValue
		}
	}
	
	final var foldersLastUpdateError: FoldersControllerError? {
		get {
			return UserDefaults.standard.decodeInGetter()
		}
		set {
			UserDefaults.standard.encodeInSetter(newValue as NSError?)
		}
	}
	
	var foldersUpdateState: FoldersUpdateState = .completed
}
