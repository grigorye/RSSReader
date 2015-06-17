//
//  GenericExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData
#if ANALYTICS_ENABLED
#if CRASHLYTICS_ENABLED
import Crashlytics
#endif
#endif

private let traceToNSLogEnabled = true

var traceEnabled: Bool {
	return defaults.traceEnabled
}
var traceLabelsEnabled: Bool {
	return defaults.traceLabelsEnabled
}

func description<T>(value: T) -> String {
	return "\(value)"
}

struct SourceLocation {
	let file: String
	let line: Int
	let column: Int
	let function: String
	let bundle: NSBundle
	init(file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__, bundle: NSBundle = NSBundle.bundleOnStack()) {
		self.file = file
		self.line = line
		self.column = column
		self.function = function
		self.bundle = bundle
	}
}

func labelFromLocations(firstLocation: SourceLocation, lastLocation: SourceLocation) -> String {
	let fileName = firstLocation.file.lastPathComponent
	let bundle = firstLocation.bundle
	let file = bundle.pathForResource(fileName.stringByDeletingPathExtension, ofType: fileName.pathExtension)!
	let text: NSString?
	do {
		text = try NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding)
	} catch {
		text = nil
	}
	let lines = (text?.componentsSeparatedByString("\n"))!
	let range = NSRange(location: firstLocation.column - 1, length: lastLocation.column - firstLocation.column-3)
	return (lines[firstLocation.line - 1] as NSString).substringWithRange(range)
}

func traceString(string: String, location: SourceLocation, lastLocation: SourceLocation) {
	if traceEnabled {
		let labelSuffix = !traceLabelsEnabled ? "[\(location.column)-\(lastLocation.column)]" : {
			return ": \(labelFromLocations(location, lastLocation: lastLocation))"
		}()
		let message = "\(location.file.lastPathComponent), \(location.function).\(location.line)\(labelSuffix): \(string)"
#if ANALYTICS_ENABLED
#if CRASHLYTICS_ENABLED
		CLSLogv("%@", getVaList([message]))
#endif
#endif
		if traceToNSLogEnabled {
			NSLog("%@", message)
		}
		else {
			print(message)
		}
	}
}

struct Traceable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: __FILE__, line: __LINE__, column: __COLUMN__, function: __FUNCTION__)) {
		self.value = value
		self.location = location
	}
	func $(level: Int = 1, file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__) -> T {
		if 0 != level {
			trace(value, startLocation: self.location, endLocation: SourceLocation(file: file, line: line, column: column, function: function))
		}
		return value
	}
}

func $<T>(v: T, file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__, bundle: NSBundle = NSBundle.bundleOnStack()) -> Traceable<T> {
	return Traceable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle))
}

func trace<T>(value: T, startLocation: SourceLocation, endLocation: SourceLocation) -> T {
	traceString(description(value), location: startLocation, lastLocation: endLocation)
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
		let (prefix, suffix) = $0
		return ("\(prefix)\(suffix)\($1)", "&")
	}.prefix
}

func filterObjectsByType<T>(objects: [AnyObject]) -> [T] {
	let filteredObjects = objects.reduce([T]()) {
		if let x = $($1).$() as? T {
			return $0 + [x]
		}
		else {
			return $0
		}
	}
	return filteredObjects
}

func stringFromFetchedResultsChangeType(type: NSFetchedResultsChangeType) -> String {
	switch (type) {
	case .Insert:
		return "Insert"
	case .Delete:
		return "Delete"
	case .Update:
		return "Update"
	case .Move:
		return "Move"
	}
}

func nilForNull(object: AnyObject) -> AnyObject? {
	if (object as! NSObject) == NSNull() {
		return nil
	}
	else {
		return object
	}
}
