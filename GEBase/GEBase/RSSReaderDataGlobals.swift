//
//  RSSReaderDataGlobals.swift
//  RSSReader
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

public extension NSUserDefaults {
	public var batchSavingDisabled: Bool {
		return self.boolForKey("batchSavingDisabled")
	}
	var traceEnabled: Bool {
		return self.boolForKey("traceEnabled")
	}
	var traceLabelsEnabled: Bool {
		return self.boolForKey("traceLabelsEnabled")
	}
}

public let defaults = NSUserDefaults()

public let progressEnabledURLSessionTaskGenerator = ProgressEnabledURLSessionTaskGenerator()
