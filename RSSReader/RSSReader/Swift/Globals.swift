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

let applicationDelegate: AppDelegate = {
	return (UIApplication.sharedApplication().delegate as! AppDelegate)
}()

let userCachesDirectoryURL: NSURL = {
	let fileManager = NSFileManager.defaultManager()
	let $ = try! fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
	return $
}()

extension NSObject {
	var foldersController: FoldersController {
		return applicationDelegate
	}
	var rssSession: RSSSession? {
		get {
			return applicationDelegate.internals.rssSession
		}
		set {
			applicationDelegate.internals.rssSession = newValue
		}
	}
}

let dateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Abbreviated
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.allowedUnits = [.Minute, .Year, .Month, .WeekOfMonth, .Day, .Hour]
	return $;
}()
