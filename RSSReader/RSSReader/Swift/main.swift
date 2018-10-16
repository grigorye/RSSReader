//
//  main.swift
//  RSSReader
//
//  Created by Grigory Entin on 14.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import func GEFoundation.defaultLogger
import var GETracing.logRecord
import Loggy
import UIKit.UIApplication

extension TypedUserDefaults {
	@NSManaged var resetDefaults: Bool
}

var launchingCompleted: (() -> Void)!

Activity(named: "Launching").execute { done in
	launchingCompleted = {
		done()
	}
}
	
if defaults.resetDefaults {
	UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
}

logRecord = defaultLogger

x$(CommandLine.arguments)

_ = UIApplicationMain(
	CommandLine.argc,
	UnsafeMutableRawPointer(CommandLine.unsafeArgv)
		.bindMemory(
			to: UnsafeMutablePointer<Int8>.self,
			capacity: Int(CommandLine.argc)),
	nil,
	NSStringFromClass(AppDelegate.self)
)
