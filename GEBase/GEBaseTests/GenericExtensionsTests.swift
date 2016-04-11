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
		traceLabelsEnabledEnforced = false
		blocksForTearDown += [{
			traceLabelsEnabledEnforced = nil
		}]
		traceEnabledEnforced = false
		blocksForTearDown += [{
			traceEnabledEnforced = nil
		}]
	}
	override func tearDown() {
		for block in blocksForTearDown {
			block()
		}
	}
	// MARK:-
    func testLabeledString() {
		let foo = "bar"
		traceLabelsEnabledEnforced = true
		XCTAssertEqual(L(foo), "foo: bar")
		traceLabelsEnabledEnforced = false
		XCTAssertEqual(L(foo), "bar")
    }
}

class TraceTests: TraceAndLabelTestsBase {
	let foo = "bar"
	var tracedMessages = [(label: String, location: SourceLocation, message: String)]()
	override func setUp() {
		let oldLoggers = loggers
		loggers += [{ date, label, location, message in
			self.tracedMessages += [(label, location, message)]
		}]
		blocksForTearDown += [{
			loggers = oldLoggers
		}]
	}
    func testTraceWithAllThingsDisabled() {
		$(foo)
		XCTAssertTrue(tracedMessages.isEmpty)
	}
	func testTraceWithTraceEanbled() {
		traceEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = NSURL.fileURLWithPath(#file)
		XCTAssertEqual(tracedMessages.map {$0.location.line}, [line])
		XCTAssertEqual(tracedMessages.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedMessages.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedMessages.map {$0.label}, ["[5-2]"])
	}
	func testWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		traceLabelsEnabledEnforced = true
		$(foo); let line = #line
		let fileURL = NSURL.fileURLWithPath(#file)
		XCTAssertEqual(tracedMessages.map {$0.location.line}, [line])
		XCTAssertEqual(tracedMessages.map {$0.location.fileURL}, [fileURL])
		XCTAssertEqual(tracedMessages.map {$0.message}, ["bar"])
		XCTAssertEqual(tracedMessages.map {$0.label}, ["foo"])
	}
}