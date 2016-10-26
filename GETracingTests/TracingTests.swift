//
//  TracingTests.swift
//  GEBase
//
//  Created by Grigory Entin on 22/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

@testable import GETracing
import XCTest

class TraceAndLabelTestsBase: XCTestCase {
	let foo = "bar"
	let bar = "baz"
	var blocksForTearDown = [() -> Void]()
	// MARK:-
	override func setUp() {
		super.setUp()
		let sourceLabelsEnabledEnforcedOldValue = sourceLabelsEnabledEnforced
		blocksForTearDown += [{
			sourceLabelsEnabledEnforced = sourceLabelsEnabledEnforcedOldValue
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
	var tracedRecords = [LogRecord]()
	override func setUp() {
		super.setUp()
		let oldLoggers = loggers
		loggers.append({ record in
			self.tracedRecords += [record]
		})
		blocksForTearDown += [{
			loggers = oldLoggers
		}]
	}
	// MARK: -
    func testTraceWithAllThingsDisabled() {
		var evaluated = false
		$({evaluated = true}())
		XCTAssertTrue(tracedRecords.isEmpty)
		XCTAssertTrue(evaluated)
	}
    func testNotraceWithAllThingsDisabled() {
		var evaluated = false
		•({evaluated = true}())
		XCTAssertTrue(tracedRecords.isEmpty)
		XCTAssertFalse(evaluated)
	}
	func testTraceWithTraceEnabled() {
		traceEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, [".5"])
	}
	func testWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo"])
	}
	func testWithTraceAndLabelsEnabledAndDumpInTraceEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		dumpInTraceEnabledEnforced = true; defer { dumpInTraceEnabledEnforced = nil }
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["- \"bar\"\n"])
		XCTAssertEqual(tracedRecords.flatMap {$0.label}, ["foo"])
	}
	func testWithTraceLockAndTracingEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let dt = disableTrace(); defer { _ = dt }
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
	func testWithTraceLockAndTracingDisabled() {
		let dt = disableTrace(); defer { _ = dt }
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
	func testWithTraceUnlockAndTracingEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let dt = disableTrace(); defer { _ = dt }
		$(bar)
		let et = enableTrace(); defer { _ = et }
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo"])
	}
	func testWithTraceUnlockWithoutLockAndTracingEnabled() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let et = enableTrace(); defer { _ = et }
		$(foo); let line = #line
		let fileURL = URL(fileURLWithPath: #file)
		XCTAssertEqual(tracedRecords.map {$0.location.line}, [line])
		XCTAssertEqual(tracedRecords.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedRecords.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedRecords.map {$0.label!}, ["foo"])
	}
	func testWithTraceUnlockAndTracingDisabled() {
		let dt = disableTrace(); defer { _ = dt }
		$(bar)
		let et = enableTrace(); defer { _ = et }
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
	func testWithDisabledFile() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		let oldFilesWithTracingDisabled = filesWithTracingDisabled
		defer { filesWithTracingDisabled = oldFilesWithTracingDisabled }
		filesWithTracingDisabled += [
			URL(fileURLWithPath: #file).lastPathComponent
		]
		$(foo)
		XCTAssertTrue(tracedRecords.isEmpty)
	}
}

class LabelTests : TraceAndLabelTestsBase {
    func testLabeledString() {
		let foo = "bar"
		sourceLabelsEnabledEnforced = true
		XCTAssertEqual(L(foo), "foo: bar")
		sourceLabelsEnabledEnforced = false
		let cln = #column
		let l = L(foo);
		XCTAssertEqual(l, ".\(cln): bar")
    }
	func testLabelWithMissingSource() {
		sourceLabelsEnabledEnforced = true
		let s = "foo"
		let sourceFile = "/tmp/Missing.swift"
		let sourceFilename = URL(fileURLWithPath: sourceFile).lastPathComponent
		let cls = type(of: self)
		let bundleFilename = Bundle(for: cls).bundleURL.lastPathComponent
		let cln = #column - 1
		let l = L(s, file: sourceFile)
		XCTAssertEqual(l, "\(bundleFilename)/\(sourceFilename)[missing]:.\(cln):?: foo")
	}
	func testLabelWithNoSource() {
		sourceLabelsEnabledEnforced = true
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
		sourceLabelsEnabledEnforced = true
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
