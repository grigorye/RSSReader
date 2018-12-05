//
//  ThrowifyTests.swift
//  GEFoundationTests
//
//  Created by Grigory Entin on 14/08/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GEFoundation
import XCTest

class ThrowifyTests: XCTestCase {

	func testBool() {
		XCTAssertThrowsError(try throwify(false))
		XCTAssertNoThrow(try throwify(true))
	}

	func testOptional() {
		XCTAssertThrowsError(try throwify(nil as String?))
		XCTAssertNoThrow(try throwify("x" as String?))
	}
}
