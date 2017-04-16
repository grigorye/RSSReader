//
//  TypedUserDefaultsTests.swift
//  GEBase
//
//  Created by Grigory Entin on 23.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

@testable import GEFoundation
import Foundation

import XCTest

extension TypedUserDefaults {
	@NSManaged var testInt: Int
}
class KVOCompliantUserDefaultsTests : XCTestCase {
	func testDeinit() {
		_ = TypedUserDefaults()
	}
	func testChangeToSameValue() {
		let d = TypedUserDefaults()
		d.testInt = 0
		d.testInt = 0
	}
}
