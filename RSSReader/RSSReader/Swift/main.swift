//
//  main.swift
//  RSSReader
//
//  Created by Grigory Entin on 14.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import Loggy
import UIKit.UIApplication

var launchingScope = Activity("Launching").enter()

extension KVOCompliantUserDefaults {
	@NSManaged var resetDefaults: Bool
}
if defaults.resetDefaults {
	UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
}

loggers += [
	defaultLogger
]

filesWithTracingDisabled += [
	"KVOCompliantUserDefaults.swift"
]

UIApplicationMain(
	CommandLine.argc,
	UnsafeMutableRawPointer(CommandLine.unsafeArgv)
		.bindMemory(
			to: UnsafeMutablePointer<Int8>.self,
			capacity: Int(CommandLine.argc)),
	nil,
	NSStringFromClass(AppDelegate.self)
)
