//
//  Globals.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit
import CoreData

let defaults = KVOCompliantUserDefaults()

let applicationDomain = "com.grigoryentin.RSSReader"

var foldersController: FoldersController!

let applicationDelegate = (UIApplication.shared.delegate as! AppDelegate)

let userCachesDirectoryURL: URL = {
	let fileManager = FileManager.default
	let $ = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
	return $
}()

extension NSObject {
	var foldersController: FoldersController {
		return applicationDelegate
	}
}
var rssSession: RSSSession? {
	get {
		return applicationDelegate.internals.rssSession
	}
	set {
		applicationDelegate.internals.rssSession = newValue
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
