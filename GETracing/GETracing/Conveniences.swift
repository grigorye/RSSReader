//
//  Conveniences.swift
//  GETracing
//
//  Created by Grigory Entin on 24.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

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
public func $<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> T {
	let value = valueClosure()
	traceAsNecessary(value, file: file, line: line, column: column, function: function, moduleReference: .dso(dso), traceFunctionName: "$")
	return value
}

@discardableResult
public func z$<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> T {
	let value = valueClosure()
	traceAsNecessary(value, file: file, line: line, column: column, function: function, moduleReference: .dso(dso), traceFunctionName: "z$")
	return value
}
