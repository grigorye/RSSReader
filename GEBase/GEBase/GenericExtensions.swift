//
//  GenericExtensions.swift
//  GEBase
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

public struct SourceLocation {
	let fileURL: NSURL
	let line: Int
	let column: Int
	let function: String
	let bundle: NSBundle?
	public init(file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__, bundle: NSBundle? = NSBundle.bundleOnStack()) {
		self.fileURL = NSURL(fileURLWithPath: file)
		self.line = line
		self.column = column
		self.function = function
		self.bundle = bundle
	}
}

func descriptionForInLineLocation(firstLocation: SourceLocation, lastLocation: SourceLocation) -> String {
	return "[\(firstLocation.column)-\(lastLocation.column - 3)]"
}

func labelFromLocation(firstLocation: SourceLocation, lastLocation: SourceLocation) -> String {
	let fileURL = firstLocation.fileURL
	let resourceName = fileURL.URLByDeletingPathExtension!.lastPathComponent!
	let resourceType = fileURL.pathExtension!
	guard let bundle = firstLocation.bundle else {
		// Console
		return "\(resourceName).\(resourceType):?"
	}
	let bundleName = (bundle.bundlePath as NSString).lastPathComponent
	guard let file = bundle.pathForResource(resourceName, ofType: resourceType, inDirectory: "Sources") else {
		// File missing in the bundle
		return "\(bundleName)/\(resourceName).\(resourceType)[!exist]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	guard let text = try? NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding) else {
		return "\(bundleName)/\(resourceName).\(resourceType)[!read]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	let lines = text.componentsSeparatedByString("\n")
	let range = NSRange(location: (firstLocation.column - 1), length: (lastLocation.column - firstLocation.column - 3))
	return (lines[firstLocation.line - 1] as NSString).substringWithRange(range)
}

public func labeledString(string: String, location: SourceLocation, lastLocation: SourceLocation) -> String {
	guard traceLabelsEnabled else {
		return string
	}
	let label = labelFromLocation(location, lastLocation: lastLocation)
	let labeledString = "\(label): \(string)"
	return labeledString
}

func messageForTracedString(string: String, location: SourceLocation, lastLocation: SourceLocation) -> String {
	let labelSuffix = !traceLabelsEnabled ? descriptionForInLineLocation(location, lastLocation: lastLocation) : {
		return ": \(labelFromLocation(location, lastLocation: lastLocation))"
	}()
	let message = "\(location.fileURL.lastPathComponent!), \(location.function).\(location.line)\(labelSuffix): \(string)"
	return message
}

var traceMessage: String -> () = { message in
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

public func traceString(string: String, location: SourceLocation, lastLocation: SourceLocation) {
	let message = messageForTracedString(string, location: location, lastLocation: lastLocation)
	traceMessage(message)
}

public struct Traceable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: __FILE__, line: __LINE__, column: __COLUMN__, function: __FUNCTION__)) {
		self.value = value
		self.location = location
	}
	public func $(level: Int = 0, file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__) -> T {
		if 0 != level {
			trace(value, startLocation: self.location, endLocation: SourceLocation(file: file, line: line, column: column, function: function))
		}
		return value
	}
}

public struct Labelable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: __FILE__, line: __LINE__, column: __COLUMN__, function: __FUNCTION__)) {
		self.value = value
		self.location = location
	}
	public func $(file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__) -> String {
		return labelValue(value, startLocation: self.location, endLocation: SourceLocation(file: file, line: line, column: column, function: function))
	}
}

public func $<T>(v: T, file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__, bundle: NSBundle? = NSBundle.bundleOnStack()) -> Traceable<T> {
	return Traceable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle))
}

public func L<T>(v: T, file: String = __FILE__, line: Int = __LINE__, column: Int = __COLUMN__, function: String = __FUNCTION__, bundle: NSBundle? = NSBundle.bundleOnStack()) -> Labelable<T> {
	return Labelable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle))
}

func trace<T>(value: T, startLocation: SourceLocation, endLocation: SourceLocation) -> T {
	if traceEnabled {
		traceString(description(value), location: startLocation, lastLocation: endLocation)
	}
	return value
}

func labelValue<T>(value: T, startLocation: SourceLocation, endLocation: SourceLocation) -> String {
	return labeledString(description(value), location: startLocation, lastLocation: endLocation)
}

public func void<T>(value: T) {
}

public typealias Handler = () -> Void
public func invoke(handler: Handler) {
	handler()
}

public func URLQuerySuffixFromComponents(components: [String]) -> String {
	return components.reduce((prefix: "", suffix: "?")) {
		let (prefix, suffix) = $0
		return ("\(prefix)\(suffix)\($1)", "&")
	}.prefix
}

public func filterObjectsByType<T>(objects: [AnyObject]) -> [T] {
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

public func nilForNull(object: AnyObject) -> AnyObject? {
	if (object as! NSObject) == NSNull() {
		return nil
	}
	else {
		return object
	}
}
