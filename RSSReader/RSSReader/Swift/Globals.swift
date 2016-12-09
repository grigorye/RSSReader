//
//  Globals.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit
import CoreData

let applicationDomain = "com.grigoryentin.RSSReader"

let applicationDelegate = (UIApplication.shared.delegate as! AppDelegate)

let userCachesDirectoryURL: URL = {
	let fileManager = FileManager.default
	let $ = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
	return $
}()

private let globalFoldersController = GlobalFoldersController()

extension NSObject {
	@objc var foldersController: GlobalFoldersController {
		return globalFoldersController
	}
}

private var sharedRSSAccount = SharedRSSAccount()

extension NSObject {
	@objc var rssAccount: SharedRSSAccount {
		return sharedRSSAccount
	}
}

var rssSession: RSSSession? {
	get {
		return sharedRSSAccount.session
	}
	set {
		sharedRSSAccount.session = newValue
	}
}

let dateComponentsFormatter = DateComponentsFormatter() … {
	$0.unitsStyle = .abbreviated
	$0.allowsFractionalUnits = true
	$0.maximumUnitCount = 1
	$0.allowedUnits = [.minute, .year, .month, .weekOfMonth, .day, .hour]
}

let loadAgoDateComponentsFormatter = DateComponentsFormatter() … {
	$0.unitsStyle = .full
	$0.allowsFractionalUnits = true
	$0.maximumUnitCount = 1
	$0.allowedUnits = [.minute, .year, .month, .weekOfMonth, .day, .hour]
}

let loadAgoLongDateComponentsFormatter = DateComponentsFormatter() … {
	$0.unitsStyle = .full
	$0.allowsFractionalUnits = true
	$0.maximumUnitCount = 1
	$0.includesApproximationPhrase = true
	$0.allowedUnits = [.minute, .year, .month, .weekOfMonth, .day, .hour]
}
