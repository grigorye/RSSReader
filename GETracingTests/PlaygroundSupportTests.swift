//
//  PlaygroundSupportTests.swift
//  GETracingTests
//
//  Created by Grigory Entin on 31.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

@testable import GETracing
import XCTest

let playgroundFile = #file

class PlaygroundSupportTests : TraceAndLabelTestsBase {
	
	func testSimple() {
		
		traceEnabledEnforced = true
		sourceLabelsEnabledEnforced = true
		
		_ = x$(0)
	}
}
