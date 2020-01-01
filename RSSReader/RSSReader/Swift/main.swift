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

if defaults.resetDefaults {
	UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
}

logRecord = defaultLogger

x$(CommandLine.arguments)

_ = UIApplicationMain(
	CommandLine.argc,
	CommandLine.unsafeArgv,
	nil,
	NSStringFromClass(AppDelegate.self)
)
