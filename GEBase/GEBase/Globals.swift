//
//  RSSReaderDataGlobals.swift
//  RSSReader
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension KVOCompliantUserDefaults {
	var traceEnabled: Bool {
		return NSUserDefaults.standardUserDefaults().boolForKey("traceEnabled")
	}
	var traceLabelsEnabled: Bool {
		return NSUserDefaults.standardUserDefaults().boolForKey("traceLabelsEnabled")
	}
}

public let defaults = KVOCompliantUserDefaults()

public let progressEnabledURLSessionTaskGenerator = ProgressEnabledURLSessionTaskGenerator()
