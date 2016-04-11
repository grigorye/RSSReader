//
//  Tracing.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

var swiftHashColumnMatchesLastComponentInCompoundExpressions = true

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
	public init(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, bundle: NSBundle? = NSBundle.bundleOnStack()) {
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

func indexOfClosingBracket(string: NSString, openingBracket: NSString, closingBracket: NSString) -> Int {
	let openingBracketIndex = string.rangeOfString(openingBracket as String).location
	let closingBracketIndex = string.rangeOfString(closingBracket as String).location
	guard (openingBracketIndex != NSNotFound) && (openingBracketIndex < closingBracketIndex) else {
		return closingBracketIndex
	}
	let tailIndex = openingBracketIndex + openingBracket.length
	let tail = string.substringFromIndex(tailIndex) as NSString
	let ignoredClosingBracketIndex = indexOfClosingBracket(tail, openingBracket: openingBracket, closingBracket: closingBracket)
	let remainingStringIndex = ignoredClosingBracketIndex + closingBracket.length
	return tailIndex + remainingStringIndex + indexOfClosingBracket(tail.substringFromIndex(remainingStringIndex), openingBracket: openingBracket, closingBracket: closingBracket)
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
	guard let fileContents = try? NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding) else {
		return "\(bundleName)/\(resourceName).\(resourceType)[!read]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	let lines = fileContents.componentsSeparatedByString("\n")
	let line = lines[firstLocation.line - 1] as NSString
	let firstIndex = firstLocation.column - 1
	let lineSuffix = line.substringFromIndex(firstIndex) as NSString
	let lengthInLineSuffix: Int = {
		guard firstLocation.column != lastLocation.column else {
			return indexOfClosingBracket(lineSuffix, openingBracket: "(", closingBracket: ")")
		}
		return lastLocation.column - firstLocation.column - 3
	}()
	let suffix = lineSuffix.substringToIndex(lengthInLineSuffix)
	guard swiftHashColumnMatchesLastComponentInCompoundExpressions else {
		return suffix
	}
	let linePrefixReversed = String(line.substringToIndex(firstIndex).characters.reverse()) as NSString
	let lengthInLinePrefixReversed: Int = {
		guard firstLocation.column != lastLocation.column else {
			return indexOfClosingBracket(linePrefixReversed, openingBracket: ")", closingBracket: "(")
		}
		return 0
	}()
	let prefix = String(linePrefixReversed.substringToIndex(lengthInLinePrefixReversed).characters.reverse())
	let text = prefix + suffix
	return text
}

public func labeledString(string: String, location: SourceLocation, lastLocation: SourceLocation) -> String {
	guard traceLabelsEnabled else {
		return string
	}
	let label = labelFromLocation(location, lastLocation: lastLocation)
	let labeledString = "\(label): \(string)"
	return labeledString
}

func labelForTracedLocation(location: SourceLocation, lastLocation: SourceLocation) -> String {
	let label = !traceLabelsEnabled ? descriptionForInLineLocation(location, lastLocation: lastLocation) : {
		return "\(labelFromLocation(location, lastLocation: lastLocation))"
	}()
	return label
}

public typealias Logger = (date: NSDate, label: String, location: SourceLocation, message: String) -> ()

public var loggers: [Logger] = [
	defaultLogger
]

func logString(date: NSDate, label: String, location: SourceLocation, message: String) {
	for logger in loggers {
		logger(date: date, label: label, location: location, message: message)
	}
}

public func traceString(string: String, date: NSDate, location: SourceLocation, lastLocation: SourceLocation) {
	let label = labelForTracedLocation(location, lastLocation: lastLocation)
	logString(date, label: label, location: location, message: string)
}

private let defaultTraceLevel = 0x0badf00d
private let defaultTracingEnabled = true

public var filesWithTracingDisabled = [String]()

public func tracingShouldBeEnabledForFile(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Bool {
	let fileURL = NSURL(fileURLWithPath: file)
	guard !filesWithTracingDisabled.contains(fileURL.lastPathComponent!) else {
		return false
	}
	return true
}

public struct Traceable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: #file, line: #line, column: #column, function: #function)) {
		self.value = value
		self.location = location
	}
	public func $(level: Int = defaultTraceLevel, date: NSDate = NSDate(), file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> T {
		if 1 == level || ((level == defaultTraceLevel) && defaultTracingEnabled && tracingShouldBeEnabledForFile(file, line: line, function: function)) {
			let column = column + ((level == defaultTraceLevel) ? 0 : -1)
			trace(value, date: date, startLocation: self.location, endLocation: SourceLocation(file: file, line: line, column: column, function: function))
		}
		return value
	}
}

public struct Labelable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: #file, line: #line, column: #column, function: #function)) {
		self.value = value
		self.location = location
	}
	public func $(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> String {
		return labelValue(value, startLocation: self.location, endLocation: SourceLocation(file: file, line: line, column: column, function: function))
	}
}

public func x$<T>(v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, bundle: NSBundle? = NSBundle.bundleOnStack()) -> Traceable<T> {
	return Traceable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle))
}

public func xL<T>(v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, bundle: NSBundle? = NSBundle.bundleOnStack()) -> Labelable<T> {
	return Labelable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle))
}

public func $<T>(v: T, date: NSDate = NSDate(), file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, bundle: NSBundle? = NSBundle.bundleOnStack()) -> T {
	let location = SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle)
	trace(v, date: date, startLocation: location, endLocation: location)
	return v
}

prefix operator • {}
public prefix func •<T>(v: T) -> T {
	return v
}

prefix operator « {}
public prefix func «<T>(v: T) -> T {
	return v
}

postfix operator » {}
public postfix func »<T>(v: T) -> T {
	return v
}

public func L<T>(v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, bundle: NSBundle? = NSBundle.bundleOnStack()) -> String {
	let location = SourceLocation(file: file, line: line, column: column, function: function, bundle: bundle)
	return labelValue(v, startLocation: location, endLocation: location)
}

func trace<T>(value: T, date: NSDate, startLocation: SourceLocation, endLocation: SourceLocation) -> T {
	if traceEnabled {
		traceString(description(value), date: date, location: startLocation, lastLocation: endLocation)
	}
	return value
}

func labelValue<T>(value: T, startLocation: SourceLocation, endLocation: SourceLocation) -> String {
	return labeledString(description(value), location: startLocation, lastLocation: endLocation)
}
