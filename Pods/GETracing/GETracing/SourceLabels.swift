//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func descriptionForInLineLocation(column: UInt) -> String {
	return ".\(column)"
}

public var sourceLabelsEnabledEnforced: Bool?

var sourceLabelsEnabled: Bool {
	return sourceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "sourceLabelsEnabled")
}
public func labelForArguments(of calleeName: StaticString, file: StaticString, line: Int, column: UInt, function: StaticString, dso: UnsafeRawPointer) -> String {
	guard sourceLabelsEnabled else {
		return descriptionForInLineLocation(column: column)
	}
	do {
		let sourceFileURL = try sourceFileURLFor(file: file, dso: dso)
		
		return try literalForArguments(of: calleeName, sourceFileURL: sourceFileURL, line: line, column: column, function: function)
	} catch {
		trackSourceLabelError(error)
		return descriptionForInLineLocation(column: column) + ":?"
	}
}

public func labelForArguments(of calleeName: StaticString, location: SourceLocation) -> String {
	let line = location.line
	let column = location.column
	let function = location.function
	guard sourceLabelsEnabled else {
		return descriptionForInLineLocation(column: column)
	}
	do {
		let sourceFileURL = try location.sourceFileURL()
		
		return try literalForArguments(of: calleeName, sourceFileURL: sourceFileURL, line: line, column: column, function: function)
	} catch {
		trackSourceLabelError(error)
		return descriptionForInLineLocation(column: column)
	}
}

public func trackSourceLabelError(_ error: Error) {
}
