//
//  SourceLocation.swift
//  GEBase
//
//  Created by Grigory Entin on 05/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

struct SourceFileAndFunction {
	let fileURL: URL
	let function: String
}

extension SourceFileAndFunction: Hashable {
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(fileURL)
		hasher.combine(function)
	}
}

func == (lhs: SourceFileAndFunction, rhs: SourceFileAndFunction) -> Bool {
	return (lhs.fileURL == rhs.fileURL) && (lhs.function == rhs.function)
}

// MARK: -

public struct SourceLocation {

	public let file: StaticString
	public let fileURL: URL
	public let line: Int
	public let column: UInt
	public let function: StaticString
	public let moduleReference: ModuleReference
	
	public enum ModuleReference {
		case dso(UnsafeRawPointer)
		case playground(name: String)
	}
	
	public init(file: StaticString = #file, line: Int = #line, column: UInt = #column, function: StaticString = #function, moduleReference: ModuleReference) {
		self.fileURL = URL(fileURLWithPath: file.description)
		self.file = file
		self.line = line
		self.column = column
		self.function = function
		self.moduleReference = moduleReference
	}
	
	public init(file: StaticString = #file, line: Int = #line, column: UInt = #column, function: StaticString = #function, dso: UnsafeRawPointer = #dsohandle) {
		self.init(file: file, line: line, column: column, function: function, moduleReference: .dso(dso))
	}
}

extension SourceLocation {

	private var playgroundName: String? {
		guard case .playground(name: let playgroundName) = moduleReference else {
			return nil
		}
		return playgroundName
	}
	
	public var sourceName: String {
		return playgroundName ?? fileURL.lastPathComponent
	}
	
	public func sourceFileURL() throws -> URL {
		switch moduleReference {
		case .dso(let dso):
			return try sourceFileURLFor(file: file, dso: dso)
		case .playground:
			return fileURL
		}
	}
}

extension SourceLocation {
	
	var fileAndFunction: SourceFileAndFunction {
		return SourceFileAndFunction(fileURL: fileURL, function: function.description)
	}
}
