//
//  Tracing.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func description<T>(of value: T) -> String {
	return "\(value)"
}

func labeled(_ string: String, at location: SourceLocation) -> String {
	guard traceLabelsEnabled else {
		return string
	}
	let locationLabel = label(for: location)
	let labeledString = "\(locationLabel): \(string)"
	return labeledString
}

/// Returns label used in `trace`.
func traceLabel(for location: SourceLocation) -> String {
	guard traceLabelsEnabled else {
		return descriptionForInLineLocation(location)
	}
	return "\(label(for: location))"
}

public typealias Logger = ((date: Date, label: String?, location: SourceLocation, message: String)) -> ()

/// Loggers to be used with `trace`.
public var loggers: [Logger] = [
]

func log(message: String, withLabel label: String?, on date: Date, at location: SourceLocation) {
	for logger in loggers {
		logger(date, label, location, message)
	}
}

struct StringOutputStream : TextOutputStream {
	var s = ""
	mutating func write(_ string: String) {
		s += string
	}
}

func trace(_ string: String, on date: Date, at location: SourceLocation) {
	let label = traceLabel(for: location)
	log(message: string, withLabel: label, on: date, at: location)
}

func trace<T>(_ v: T, file: String, line: Int, column: Int, function: String, dso: UnsafeRawPointer) {
	let location = SourceLocation(file: file, line: line, column: column, function: function, dso: dso)
	trace(v, at: location)
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

public func L<T>(_ v: T, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle) -> String {
	let location = SourceLocation(file: file, line: line, column: column, function: function, dso: dso)
	return labeled(description(of: v), at: location)
}

func trace<T>(_ value: T, at location: SourceLocation) {
	guard tracingShouldBeEnabledForLocation(location) else {
		return
	}
	guard dumpInTraceEnabled else {
		trace(description(of: value), on: Date(), at: location)
		return
	}
	let label = traceLabel(for: location)
	var ss = StringOutputStream()
	dump(value, to: &ss, name: label)
	log(message: "\n\(ss.s)", withLabel: nil, on: Date(), at: location)
}
