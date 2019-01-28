//
//  Tracing.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

protocol LoggedValue {
	func logMessage() -> LogRecord.Message
}

struct MultilineLoggedValue : LoggedValue {
	let data: Data
	func logMessage() -> LogRecord.Message {
		return .multiline(data)
	}
}

struct InlineLoggedValue<T> : LoggedValue {
	let value: T
	func logMessage() -> LogRecord.Message {
		return .inline(value)
	}
}

func newLoggedValue<T>(for value: T) -> LoggedValue {
	if let value = value as? Multiline {
		return MultilineLoggedValue(data: value.data)
	}
	return InlineLoggedValue(value: value)
}

public func traceAsNecessary<T>(_ value: T, file: StaticString, line: Int, column: UInt, function: StaticString, moduleReference: SourceLocation.ModuleReference, traceFunctionName: StaticString) {
	// swiftlint:disable:previous function_parameter_count
	#if GE_TRACE_ENABLED
	guard traceEnabled else {
		return
	}
	let location = SourceLocation(file: file, line: line, column: column, function: function, moduleReference: moduleReference)
	guard tracingEnabled(for: location) else {
		return
	}
	log(newLoggedValue(for: value), on: Date(), at: location, traceFunctionName: traceFunctionName)
	#endif
}

public var traceEnabledEnforced: Bool?

var traceEnabled: Bool {
	return traceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "traceEnabled")
}
