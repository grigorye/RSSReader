//
//  SourceLocation.swift
//  GEBase
//
//  Created by Grigory Entin on 05/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

struct SourceFileAndFunction {
	let fileURL: NSURL
	let function: String
}
extension SourceFileAndFunction: Hashable {
	var hashValue: Int {
		return fileURL.hashValue &+ function.hashValue
	}
}
func == (lhs: SourceFileAndFunction, rhs: SourceFileAndFunction) -> Bool {
	return (lhs.fileURL == rhs.fileURL) && (lhs.function == rhs.function)
}

// MARK: -

struct LocationInFunction {
	let line: Int
	let column: Int
}
extension LocationInFunction: Hashable {
	var hashValue: Int {
		return line.hashValue &+ column.hashValue
	}
}
extension LocationInFunction: Equatable {
}
func == (lhs: LocationInFunction, rhs: LocationInFunction) -> Bool {
	return (lhs.column == rhs.column) && (lhs.line == rhs.line)
}
func < (lhs: LocationInFunction, rhs: LocationInFunction) -> Bool {
	guard lhs.line <= rhs.line else {
		return false
	}
	guard (lhs.line != rhs.line) || (lhs.column < rhs.column) else {
		return false
	}
	return true
}

// MARK: -

struct FunctionSourceLocationRange {
	let start: LocationInFunction
	let end: LocationInFunction?
}
extension FunctionSourceLocationRange: Hashable {
	var hashValue: Int {
		return start.hashValue &+ (end?.hashValue ?? 0)
	}
}
func == (lhs: FunctionSourceLocationRange, rhs: FunctionSourceLocationRange) -> Bool {
	return (lhs.start == rhs.start) && (lhs.end == rhs.end)
}
extension FunctionSourceLocationRange {
	func contains(other: LocationInFunction) -> Bool {
		guard start < other else {
			return false
		}
		guard let end = end else {
			return true
		}
		return other < end
	}
}

// MARK: -

public struct SourceLocation {
	let fileURL: NSURL
	let line: Int
	let column: Int
	let function: String
	let bundle: NSBundle?
	public init(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, bundle: NSBundle? = NSBundle.bundleOnStack()) {
		precondition(file != "")
		self.fileURL = NSURL(fileURLWithPath: file, isDirectory: false)
		self.line = line
		self.column = column
		self.function = function
		self.bundle = bundle
	}
}
extension SourceLocation {
	var fileAndFunction: SourceFileAndFunction {
		return SourceFileAndFunction(fileURL: fileURL, function: function)
	}
	var locationInFunction: LocationInFunction {
		return LocationInFunction(line: line, column: column)
	}
}