//
//  Descriptions.swift
//  GETracing
//
//  Created by Grigory Entin on 12.03.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

public var tracedValueDescriptionGenerator: (Any) -> String = { value in
	if dumpInTraceEnabled {
		var s = ""
		dump(value, to: &s)
		return s
	}
	return String(reflecting: value)
}

var dumpInTraceEnabledEnforced: Bool?
private var dumpInTraceEnabled: Bool {
	return dumpInTraceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "dumpInTraceEnabled")
}
