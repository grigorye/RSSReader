//
//  TracingDefaults.swift
//  GEBase
//
//  Created by Grigory Entin on 23.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

var traceLabelsEnabledEnforced: Bool?
var traceEnabledEnforced: Bool?
var dumpInTraceEnabledEnforced: Bool?

private extension KVOCompliantUserDefaults {
	@NSManaged var traceEnabled: Bool
	@NSManaged var traceLabelsEnabled: Bool
	@NSManaged var dumpInTraceEnabled: Bool
}

var traceEnabled: Bool {
	return traceEnabledEnforced ?? defaults.traceEnabled
}
var traceLabelsEnabled: Bool {
	return traceLabelsEnabledEnforced ?? defaults.traceLabelsEnabled
}
var dumpInTraceEnabled: Bool {
	return dumpInTraceEnabledEnforced ?? defaults.dumpInTraceEnabled
}
