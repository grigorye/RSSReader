//
//  Labeling.swift
//  GETracing
//
//  Created by Grigory Entin on 24.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public func L<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> String {
	// swiftlint:disable:previous identifier_name
	let value = valueClosure()
	let location = SourceLocation(file: file, line: line, column: column, function: function, moduleReference: .dso(dso))
	let sourceExtractedInfo = GETracing.sourceExtractedInfo(for: location, traceFunctionName: "L")
	let loggedValue = newLoggedValue(for: value)
	let logMessage = loggedValue.logMessage()
	let formatted = logMessage.formattedForOutput(prefixedWithLabel: true)
	let labeled = "\(sourceExtractedInfo.label):" + formatted
	return labeled
}
