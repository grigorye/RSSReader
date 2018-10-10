//
//  main.swift
//  RSSReader
//
//  Created by Grigory Entin on 14.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import func GEFoundation.defaultLogger
import var GETracing.loggers
import Loggy
import UIKit.UIApplication

var launchingScope = Activity(label: "Launching").enter()

extension TypedUserDefaults {
	@NSManaged var resetDefaults: Bool
}
if defaults.resetDefaults {
	UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
}

loggers += [
	defaultLogger
]

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
