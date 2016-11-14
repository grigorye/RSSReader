//
//  Tracing.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

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
#if GE_TRACE_ENABLED
	if traceEnabled {
		let location = SourceLocation(file: file, line: line, column: column, function: function, dso: dso)
		trace(value, at: location)
	}
#endif
	return value
}

func trace<T>(_ value: T, at location: SourceLocation) {
	guard tracingEnabled(for: location) else {
		return
	}
	log(value, on: Date(), at: location)
}

var traceEnabledEnforced: Bool?

var traceEnabled: Bool {
	return traceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "traceEnabled")
}
