//
//  KeyPathsTests.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReader
import XCTest

func void<T>(x: T) {
}

private class ObjectWithString: NSObject {
	dynamic var string: String!
}

class KeyPathsTests : XCTestCase {
	dynamic var string: String! = "bar"
	dynamic var array: [String]!
	private dynamic var objectWithString: ObjectWithString!
	private dynamic var computedObjectWithString: ObjectWithString! {
		return ObjectWithString()
	}
	private dynamic var computedArray: [ObjectWithString] {
		return [ObjectWithString]()
	}
	func testString() {
		let x = instanceKeyPath(self) {
			$0.string
		}
		XCTAssertEqual(x, "string", "")
	}
	func testArray() {
		let x = instanceKeyPath(self) {
			$0.array
		}
		XCTAssertEqual(x, "array", "")
	}
	func testComputedArray() {
		let x = instanceKeyPath(self) {
			$0.computedArray
		}
		XCTAssertEqual(x, "computedArray", "")
	}
	func testObjectWithString() {
		let x = instanceKeyPath(self) {
			$0.objectWithString.string
		}
		XCTAssertEqual(x, "objectWithString.string", "")
	}
	func testObjectWithStringOperator() {
		let x = (•self){
			$0.objectWithString.string
		}
		XCTAssertEqual(x.keyPath, "objectWithString.string", "")
	}
	func testComputedObjectWithStringOperator() {
		let x = (•self){
			$0.computedObjectWithString.string
		}
		XCTAssertEqual(x.keyPath, "computedObjectWithString.string", "")
	}
}
