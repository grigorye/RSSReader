//
//  GenericExtensionsTests.swift
//  GEBase
//
//  Created by Grigory Entin on 22/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

@testable import GEBase
import XCTest

class TraceAndLabelTestsBase: XCTestCase {
	var blocksForTearDown = [Handler]()
	// MARK:-
	override func setUp() {
		super.setUp()
		let traceLabelsEnabledEnforcedOldValue = traceLabelsEnabledEnforced
		blocksForTearDown += [{
			traceLabelsEnabledEnforced = traceLabelsEnabledEnforcedOldValue
		}]
		let traceEnabledEnforcedOldValue = traceEnabledEnforced
		blocksForTearDown += [{
			traceEnabledEnforced = traceEnabledEnforcedOldValue
		}]
		let swiftHashColumnMatchesLastComponentInCompoundExpressionsOldValue = swiftHashColumnMatchesLastComponentInCompoundExpressions
		blocksForTearDown += [{
			swiftHashColumnMatchesLastComponentInCompoundExpressions = swiftHashColumnMatchesLastComponentInCompoundExpressionsOldValue
		}]
	}
	override func tearDown() {
		blocksForTearDown.forEach {$0()}
		blocksForTearDown = []
		super.tearDown()
	}
}

class TraceTests : TraceAndLabelTestsBase {
	let foo = "bar"
	var tracedMessages = [(label: String?, location: SourceLocation, message: String)]()
	override func setUp() {
		super.setUp()
		let oldLoggers = loggers
		loggers.append({ date, label, location, message in
			self.tracedMessages += [(label: label, location: location, message: message)]
		})
		blocksForTearDown += [{
			loggers = oldLoggers
		}]
	}
	// MARK: -
    func testTraceWithAllThingsDisabled() {
		$(foo)
		XCTAssertTrue(tracedMessages.isEmpty)
	}
	func testTraceWithTraceEnabled() {
		traceEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedMessages.map {$0.location.line}, [line])
		XCTAssertEqual(tracedMessages.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedMessages.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedMessages.map {$0.label!}, ["5"])
	}
	func testWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		traceLabelsEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedMessages.map {$0.location.line}, [line])
		XCTAssertEqual(tracedMessages.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedMessages.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedMessages.map {$0.label!}, ["foo"])
	}
	// MARK: -
    func testLabeledString() {
		let foo = "bar"
		traceLabelsEnabledEnforced = true
		XCTAssertEqual(L(foo), "foo: bar")
		traceLabelsEnabledEnforced = false
		XCTAssertEqual(L(foo), "bar")
    }
	func testLabelWithMissingSource() {
		traceLabelsEnabledEnforced = true
		let s = "foo"
		let sourceFile = "/tmp/Missing.swift"
		let sourceFilename = URL(fileURLWithPath: sourceFile).lastPathComponent
		let cls = type(of: self)
		let bundleFilename = Bundle(for: cls).bundleURL.lastPathComponent
		let cln = #column - 1
		let l = L(s, file: sourceFile)
		XCTAssertEqual(l, "\(bundleFilename)/\(sourceFilename)[missing]:\(cln):?: foo")
	}
	func testLabelWithNoSource() {
		traceLabelsEnabledEnforced = true
		let s = "foo"
		var v = "foo"
		let sourceFilename = URL(fileURLWithPath: #file).lastPathComponent
		withUnsafePointer(to: &v) { p in
			let l = L(s, dso: p)
			XCTAssertEqual(l, "\(sourceFilename):?: foo")
		}
	}
	func testLabeledCompoundExpressions() {
		let foo = "bar"
		let optionalFoo = Optional("bar")
		swiftHashColumnMatchesLastComponentInCompoundExpressions = true
		traceLabelsEnabledEnforced = true
		XCTAssertEqual(L(String(foo.characters.reversed())), "String(foo.characters.reversed()): rab")
		XCTAssertEqual(L("baz" + String(foo.characters.reversed())), "\"baz\" + String(foo.characters.reversed()): bazrab")
		XCTAssertEqual(L(optionalFoo!), "optionalFoo!: bar")
		swiftHashColumnMatchesLastComponentInCompoundExpressions = false
		XCTAssertEqual(L(String(foo.characters.reversed())), "String(foo.characters.reversed()): rab")
		XCTAssertEqual(L("baz" + String(foo.characters.reversed())), "\"baz\" + String(foo.characters.reversed()): bazrab")
		XCTAssertEqual(L(optionalFoo!), "optionalFoo!: bar")
		let fileManager = FileManager.default
		let storePath = "/tmp/xxx"
		XCTAssertEqual(L(fileManager.fileExists(atPath: storePath)), "fileManager.fileExists(atPath: storePath): false")
	}
}
