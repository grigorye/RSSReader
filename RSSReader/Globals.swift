//
//  Globals.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

let defaults = NSUserDefaults()

var _1 = true
var _0 = false

extension NSObject {
	var applicationDelegate: AppDelegate {
		get {
			return (UIApplication.sharedApplication().delegate as AppDelegate)
		}
	}
	var mainQueueManagedObjectContext: NSManagedObjectContext {
		get {
			return self.applicationDelegate.internals.mainQueueManagedObjectContext!
		}
	}
	var backgroundQueueManagedObjectContext: NSManagedObjectContext {
		get {
			return self.applicationDelegate.internals.backgroundQueueManagedObjectContext!
		}
	}
	var rssSession: RSSSession! {
		get {
			return self.applicationDelegate.internals.rssSession
		}
		set {
			self.applicationDelegate.internals.rssSession = newValue
		}
	}
}

