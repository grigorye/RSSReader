//
//  Labeling.swift
//  GETracing
//
//  Created by Grigory Entin on 24.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

public func L<T>(file: StaticString = #file, line: Int = #line, column: UInt = #column, function: StaticString = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> String {
	// swiftlint:disable:previous identifier_name
	let value = valueClosure()
	let label = labelForArguments(of: "L", file: file, line: line, column: column, function: function, dso: dso)
	let loggedValue = newLoggedValue(for: value)
	let logMessage = loggedValue.logMessage()
	let formatted = logMessage.formattedForOutput(prefixedWithLabel: true)
	let labeled = "\(label):" + formatted
	return labeled
}
