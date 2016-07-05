//
//  Globals.swift
//  GEBase
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

var traceLabelsEnabledEnforced: Bool?
var traceEnabledEnforced: Bool?

extension KVOCompliantUserDefaults {
	var traceEnabled: Bool {
		return traceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "traceEnabled")
	}
	var traceLabelsEnabled: Bool {
		return traceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "traceLabelsEnabled")
	}
}

public let defaults = KVOCompliantUserDefaults()

public let progressEnabledURLSessionTaskGenerator = ProgressEnabledURLSessionTaskGenerator()
