//
//  Watchdog.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 15.11.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import Watchdog

extension TypedUserDefaults {
	
	@NSManaged var watchdogEnabled: Bool
}

let watchdogInitializer: Void = {
	_ = Watchdog(threshold: 0.4, strictMode: defaults.watchdogEnabled)
}()
