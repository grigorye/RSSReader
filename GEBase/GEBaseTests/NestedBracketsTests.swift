//
//  NestedBracketsTests.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import XCTest

class StringTests : XCTestCase {
	let s = "a.b(c))"
	let i = "0123456"
	func testClosingBracketRange() {
		XCTAssertEqual(
			s.rangeOfClosingBracket(")", openingBracket: "(")!.lowerBound,
			s.index(s.startIndex, offsetBy: 6)
		)
	}
}
