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
	var tracedMessages = [String]()
	override func setUp() {
		let oldTraceMessage = traceMessage
		traceMessage = { message in
			self.tracedMessages += [message]
		}
		blocksForTearDown += [{
			traceMessage = oldTraceMessage
		}]
	}
    func testTraceWithAllThingsDisabled() {
		$(foo)
		XCTAssertEqual(tracedMessages, [])
	}
	func testTraceWithTraceEanbled() {
		traceEnabledEnforced = true
		$(foo); let line = #line
		let fileName = NSURL.fileURLWithPath(#file).lastPathComponent!
		XCTAssertEqual(tracedMessages, ["\(fileName), \(#function).\(line)[5-8]: bar"])
	}
	func testWithTraceAndLabelsEnabled() {
		traceEnabledEnforced = true
		traceLabelsEnabledEnforced = true
		$(foo); let line = #line
		let fileName = NSURL.fileURLWithPath(#file).lastPathComponent!
		XCTAssertEqual(tracedMessages, ["\(fileName), \(#function).\(line): foo: bar"])
	}
}