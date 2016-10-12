//
//  Tracing.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
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

extension String {
	func substring(toOffset offset: Int) -> String {
		return substring(to: index(startIndex, offsetBy: offset))
	}
	func substring(fromOffset offset: Int) -> String {
		return substring(from: index(startIndex, offsetBy: offset))
	}
}

var swiftHashColumnMatchesLastComponentInCompoundExpressions = true

var traceEnabled: Bool {
	return defaults.traceEnabled
}
var traceLabelsEnabled: Bool {
	return defaults.traceLabelsEnabled
}

func description<T>(of value: T) -> String {
	return "\(value)"
}

func descriptionForInLineLocation(_ firstLocation: SourceLocation, lastLocation: SourceLocation) -> String {
	return "[\(firstLocation.column)-\(lastLocation.column - 3)]"
}

extension String {
	func rangeOfClosingBracket(_ closingBracket: String, openingBracket: String, range searchRange: Range<Index>? = nil) -> Range<String.CharacterView.Index>? {
		guard let openingBracketRange = range(of: openingBracket, range: searchRange) else {
			return range(of: closingBracket)
		}
		guard let closingBracketRange = range(of: closingBracket, range: searchRange) else {
			return nil
		}
		guard openingBracketRange.lowerBound < closingBracketRange.lowerBound else {
			return closingBracketRange
		}
		let upperBound = searchRange?.upperBound ?? self.characters.endIndex
		let tailIndex = openingBracketRange.upperBound
		let ignoredClosingBracketRange = rangeOfClosingBracket(closingBracket, openingBracket: openingBracket, range: tailIndex..<upperBound)!
		let remainingStringIndex = ignoredClosingBracketRange.upperBound
		return rangeOfClosingBracket(closingBracket, openingBracket: openingBracket, range: remainingStringIndex..<upperBound)
	}
}

func label(from firstLocation: SourceLocation, to lastLocation: SourceLocation) -> String {
	let fileURL = firstLocation.fileURL
	let resourceName = fileURL.deletingPathExtension().lastPathComponent
	let resourceType = fileURL.pathExtension
	guard let bundle = firstLocation.bundle else {
		// Console
		return "\(resourceName).\(resourceType):?"
	}
	let bundleName = (bundle.bundlePath as NSString).lastPathComponent
	guard let file = bundle.path(forResource: resourceName, ofType: resourceType, inDirectory: "Sources") else {
		// File missing in the bundle
		return "\(bundleName)/\(resourceName).\(resourceType)[!exist]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	guard let fileContents = try? String(contentsOfFile: file, encoding: String.Encoding.utf8) else {
		return "\(bundleName)/\(resourceName).\(resourceType)[!read]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	let lines = fileContents.components(separatedBy: "\n")
	let line = lines[firstLocation.line - 1]
	let firstIndex = firstLocation.column - 1
	let lineSuffix = line.substring(fromOffset: firstIndex)
	let lengthInLineSuffix: Int = {
		guard firstLocation.column != lastLocation.column else {
			let indexOfClosingBracket = lineSuffix.rangeOfClosingBracket(")", openingBracket: "(")!.lowerBound
			return lineSuffix.distance(from: lineSuffix.startIndex, to: indexOfClosingBracket)
		}
		return lastLocation.column - firstLocation.column - 3
	}()
	let suffix = lineSuffix.substring(toOffset: lengthInLineSuffix)
	guard swiftHashColumnMatchesLastComponentInCompoundExpressions else {
		return suffix
	}
	let linePrefixReversed = String(line.substring(toOffset: firstIndex).characters.reversed())
	let lengthInLinePrefixReversed: Int = {
		guard firstLocation.column != lastLocation.column else {
			let indexOfClosingBracket = linePrefixReversed.rangeOfClosingBracket("(", openingBracket: ")")!.lowerBound
			return linePrefixReversed.distance(from: linePrefixReversed.startIndex, to: indexOfClosingBracket)
		}
		return 0
	}()
	let prefix = String(linePrefixReversed.substring(toOffset: lengthInLinePrefixReversed).characters.reversed())
	let text = prefix + suffix
	return text
}

func labeled(_ string: String, from location: SourceLocation, to lastLocation: SourceLocation) -> String {
	guard traceLabelsEnabled else {
		return string
	}
	let locationLabel = label(from: location, to: lastLocation)
	let labeledString = "\(locationLabel): \(string)"
	return labeledString
}

/// Returns label used in `trace`.
func traceLabel(from location: SourceLocation, to lastLocation: SourceLocation) -> String {
	guard traceLabelsEnabled else {
		return descriptionForInLineLocation(location, lastLocation: lastLocation)
	}
	return "\(label(from: location, to: lastLocation))"
}

public typealias Logger = ((date: Date, label: String, location: SourceLocation, message: String)) -> ()

/// Loggers to be used with `trace`.
public var loggers: [Logger] = [
	defaultLogger
]

func log(message: String, withLabel label: String, on date: Date, at location: SourceLocation) {
	for logger in loggers {
		logger(date, label, location, message)
	}
}

func trace(_ string: String, on date: Date, from location: SourceLocation, to lastLocation: SourceLocation) {
	let label = traceLabel(from: location, to: lastLocation)
	log(message: string, withLabel: label, on: date, at: location)
}

private let defaultTraceLevel = 0x0badf00d
private let defaultTracingEnabled = true

public var filesWithTracingDisabled = [String]()

var traceLockCountForFileAndFunction: [SourceFileAndFunction : Int] = [:]

public class TraceLocker {
	let sourceFileAndFunction: SourceFileAndFunction
	public init(file: String = #file, function: String = #function) {
		self.sourceFileAndFunction = SourceFileAndFunction(fileURL: URL(fileURLWithPath: file), function: function)
		let oldValue = traceLockCountForFileAndFunction[self.sourceFileAndFunction] ?? 0
		traceLockCountForFileAndFunction[self.sourceFileAndFunction] = oldValue + 1
	}
	deinit {
		let oldValue = traceLockCountForFileAndFunction[self.sourceFileAndFunction]!
		traceLockCountForFileAndFunction[self.sourceFileAndFunction] = oldValue - 1
	}
}
public class TraceUnlocker {
	let sourceFileAndFunction: SourceFileAndFunction
	let unlockingWithNoLock: Bool
	public init(file: String = #file, function: String = #function) {
		self.sourceFileAndFunction = SourceFileAndFunction(fileURL: URL(fileURLWithPath: file), function: function)
		let oldValue = traceLockCountForFileAndFunction[self.sourceFileAndFunction] ?? 0
		let unlockingWithNoLock = oldValue == 0
		if !unlockingWithNoLock {
			traceLockCountForFileAndFunction[self.sourceFileAndFunction] = oldValue - 1
		}
		self.unlockingWithNoLock = unlockingWithNoLock
	}
	deinit {
		if !self.unlockingWithNoLock {
			let oldValue = traceLockCountForFileAndFunction[self.sourceFileAndFunction]!
			traceLockCountForFileAndFunction[self.sourceFileAndFunction] = oldValue + 1
		}
	}
}
public func disableTrace(file: String = #file, function: String = #function) -> TraceLocker? {
	guard traceEnabled else {
		return nil
	}
	return TraceLocker(file: file, function: function)
}
public func enableTrace(file: String = #file, function: String = #function) -> TraceUnlocker? {
	guard traceEnabled else {
		return nil
	}
	return TraceUnlocker(file: file, function: function)
}

func tracingShouldBeEnabledForLocation(_ location: SourceLocation) -> Bool {
	guard !filesWithTracingDisabled.contains(location.fileURL.lastPathComponent) else {
		return false
	}
	guard 0 == (traceLockCountForFileAndFunction[location.fileAndFunction] ?? 0) else {
		return false
	}
	return true
}

public struct Traceable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: #file, line: #line, column: #column, function: #function, dso: #dsohandle, bundle: Bundle.bundle(forStackFrameIndex: 2))) {
		self.value = value
		self.location = location
	}
	public func $(level: Int = defaultTraceLevel, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer) -> T {
		if 1 == level || ((level == defaultTraceLevel) && defaultTracingEnabled && tracingShouldBeEnabledForLocation(self.location)) {
			let column = column + ((level == defaultTraceLevel) ? 0 : -1)
			trace(value, from: self.location, to: SourceLocation(file: file, line: line, column: column, function: function, dso: dso))
		}
		return value
	}
}

public struct Labelable<T> {
	let value: T
	let location: SourceLocation
	init(value: T, location: SourceLocation = SourceLocation(file: #file, line: #line, column: #column, function: #function, dso: #dsohandle)) {
		self.value = value
		self.location = location
	}
	public func $(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle) -> String {
		return label(for: value, from: self.location, to: SourceLocation(file: file, line: line, column: column, function: function, dso: dso))
	}
}

public func x$<T>(v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, bundle: Bundle? = Bundle.bundle(forStackFrameIndex: 2)) -> Traceable<T> {
	return Traceable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, dso: dso, bundle: bundle))
}

public func xL<T>(v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, bundle: Bundle? = Bundle.bundle(forStackFrameIndex: 2)) -> Labelable<T> {
	return Labelable(value: v, location: SourceLocation(file: file, line: line, column: column, function: function, dso: dso, bundle: bundle))
}

func trace<T>(_ v: T, file: String, line: Int, column: Int, function: String, dso: UnsafeRawPointer) {
	let location = SourceLocation(file: file, line: line, column: column, function: function, dso: dso, bundle: Bundle.bundle(forStackFrameIndex: 3))
	trace(v, from: location, to: location)
}

/// Passes-through `value`, logging it as necessary with `loggers`.
///
/// Consider Baz.swift:
/// ````
/// func sinPi() -> Float {
///     let foo = Float.pi
///     let bar = sin(foo)
///     return bar
/// }
/// ````
/// Any expression used in the code might be logged by simply wrapping it in `$()`:
/// ````
/// func sinPi() -> Float {
///     let foo = Float.pi
///     $(cos(foo))
///     let bar = sin($(foo))
///     return bar
/// }
/// ````
/// When `sinPi` is executed, value for `cos(foo)` as well as `foo` passed to `sin` may be logged as below:
/// ````
/// 03:12.13.869 [-] sinPi, Baz.swift:4, cos(foo): -1
/// 03:12.13.855 [-] sinPi, Baz.swift:5, foo: 3.141593
/// ````
/// - seealso: `•`.
/// - seealso: `loggers`.
@discardableResult
public func $<T>(_ value: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle) -> T {
	if traceEnabled {
		trace(value, file: file, line: line, column: column, function: function, dso: dso)
	}
	return value
}

/// When it replaces `$` used without passing-through the logged value, disables logging and supresses evaluation of `argument`.
///
/// Consider Baz.swift that uses `$` for logging value of `cos(foo)` and `foo`:
/// ````
/// func sinPi() -> Float {
///     let foo = Float.pi
///     $(cos(foo))
///     let bar = sin($(foo))
///     return bar
/// }
/// ````
/// To temporarily supress logging *and* evaluation of `cos(foo)`
/// ````
/// $(cos(foo))
/// ````
/// should be changed to
/// ````
/// •(cos(foo))
/// ````
/// , hence replacing `$` with `•`, leaving the possibility to enable logging again just by replacing `•` with `$`.
///
/// Not adding `•` above would result in a compiler warning about unused value as well as wasting cpu on no-effect invocation.
///
/// To temporarily supress logging of `foo` (but still have it evaluated as the argument of `sin`),
/// ````
/// let bar = sin($(foo))
/// ````
/// should be changed to
/// ````
/// let bar = sin((foo))
/// ````
/// , ommitting `$`, leaving the possibility to enable logging again just by adding back `$`.
/// - seealso: `$`.
public prefix func •<T>(argument: @autoclosure () -> T) -> Void {
}
prefix operator •

prefix operator «
public prefix func «<T>(v: T) -> T {
	return v
}

postfix operator »
public postfix func »<T>(v: T) -> T {
	return v
}

public func L<T>(_ v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, bundle: Bundle? = Bundle.bundle(forStackFrameIndex: 2)) -> String {
	let location = SourceLocation(file: file, line: line, column: column, function: function, dso: dso, bundle: bundle)
	return label(for: v, from: location, to: location)
}

func trace<T>(_ value: T, from startLocation: SourceLocation, to endLocation: SourceLocation) {
	if tracingShouldBeEnabledForLocation(startLocation) {
		trace(description(of: value), on: Date(), from: startLocation, to: endLocation)
	}
}

func label<T>(for value: T, from startLocation: SourceLocation, to endLocation: SourceLocation) -> String {
	return labeled(description(of: value), from: startLocation, to: endLocation)
}
