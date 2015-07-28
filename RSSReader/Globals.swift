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

let defaults = KVOCompliantUserDefaults()

var _1 = true
var _0 = false

let applicationDomain = "com.grigoryentin.RSSReader"

var foldersController: FoldersController!

var applicationDelegate: AppDelegate {
	get {
		return (UIApplication.sharedApplication().delegate as! AppDelegate)
	}
}
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
	var progressEnabledURLSessionTaskGenerator: ProgressEnabledURLSessionTaskGenerator! {
		get {
			return applicationDelegate.internals.progressEnabledURLSessionTaskGenerator
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
