//
//  GenericExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
#if ANALYTICS_ENABLED
#if CRASHLYTICS_ENABLED
import Crashlytics
#endif
#endif

var traceEnabled: Bool = {
	return _1 ? false : defaults.traceEnabled
}()

func trace<T>(label: String, value: T, file: NSString = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) -> T {
	if traceEnabled {
		let message = "\(file.lastPathComponent), \(function).\(line): \(label): \(value)"
#if ANALYTICS_ENABLED
#if CRASHLYTICS_ENABLED
		CLSLogv("%@", getVaList([message]))
#endif
#endif
		println(message)
	}
	return value
}

func void<T>(value: T) {
}

typealias Handler = () -> Void
func invoke(handler: Handler) {
	handler()
}

func URLQuerySuffixFromComponents(components: [String]) -> String {
	return components.reduce((prefix: "", suffix: "?")) {
		switch ($0) {
		case let (prefix, suffix):
			return ("\(prefix)\(suffix)\($1)", "&")
		}
	}.prefix
}

func filterObjectsByType<T>(objects: [AnyObject]) -> [T] {
	let filteredObjects = objects.reduce([T]()) {
		if let x = trace("$1", $1) as? T {
			return $0 + [x]
		}
		else {
			return $0
		}
	}
	return filteredObjects
}