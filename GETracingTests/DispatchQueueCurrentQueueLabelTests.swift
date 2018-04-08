//
//  DispatchQueueCurrentQueueLabelTests.swift
//  GETracingTests
//
//  Created by Grigory Entin on 08/04/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GETracing
import XCTest

class DispatchQueueCurrentQueueLabelTests: TraceAndLabelTestsBase {
	
	func testExample() {
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true

		let mainQueueLabel = x$(DispatchQueue.currentQueueLabel)
		XCTAssertNotNil(mainQueueLabel)
		var globalQueueLabel: String?
		let asyncCompleted = expectation(description: "Async completed")
		DispatchQueue.global().async {
			globalQueueLabel = x$(DispatchQueue.currentQueueLabel)
			XCTAssertNotNil(globalQueueLabel)
			asyncCompleted.fulfill()
		}
		waitForExpectations(timeout: 0.1)
		XCTAssertNotEqual(mainQueueLabel, globalQueueLabel)
	}
}
