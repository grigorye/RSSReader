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

var traceEnabled: Bool {
	return traceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "traceEnabled")
}
var traceLabelsEnabled: Bool {
	return traceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "traceLabelsEnabled")
}
var dumpInTraceEnabled: Bool {
	return dumpInTraceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "dumpInTraceEnabled")
}
