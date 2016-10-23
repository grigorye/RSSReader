//
//  BundleForSymbolAddressTests.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

@testable import GETracing
import Foundation

import XCTest

class BundleForSymbolAddressTests : XCTestCase {
	func testDSOHandle() {
		XCTAssertEqual(Bundle(for: BundleForSymbolAddressTests.self), Bundle(for: #dsohandle))
	}
	func testWithNonSymbol() {
		var t = 0
		withUnsafePointer(to: &t) { p in
			XCTAssertNil(Bundle(for: p))
		}
	}
}
