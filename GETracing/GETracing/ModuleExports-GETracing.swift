//
//  ModuleExports-GETracing.swift
//  GETracing
//
//  Created by Grigory Entin on 09.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GETracing
import Foundation

internal var moduleTracingEnabled: Bool = {
	let bundle = Bundle(for: #dsohandle)!
	let valueInInfoPlist = (bundle.object(forInfoDictionaryKey: "GEModuleTracingEnabled") as! NSNumber?)?.boolValue ?? true
	return valueInInfoPlist
}()

@discardableResult
internal func $<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> T
{
	guard moduleTracingEnabled else {
		return valueClosure()
	}
	return GETracing.$(file: file, line: line, column: column, function: function, dso: dso, valueClosure)
}

internal prefix func •<T>(argument: @autoclosure () -> T) {
}

internal func L<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> String {
	return GETracing.L(file: file, line: line, column: column, function: function, dso: dso, valueClosure)
}

internal func disableTrace(file: String = #file, function: String = #function) -> Any? {
	return GETracing.disableTrace(file: file, function: function)
}
