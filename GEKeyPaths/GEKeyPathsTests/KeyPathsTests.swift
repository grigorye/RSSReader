//
//  KeyPathsTests.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import XCTest

class ObjectWithString: NSObject {
	dynamic var optionalString: String! = "baz"
	dynamic var string = "baz"
	dynamic var optionalAnotherObject: ObjectWithString! {
		return nil
	}
	dynamic var computedLength: Int {
		return (string as NSString).length
	}
}

class KeyPathsTests : XCTestCase {
	let Self_ = KeyPathsTests.self
	dynamic var string: String = "bar"
	dynamic var optionalString: String!
	dynamic var array = ["foo"]
	dynamic var optionalArray: [String]!
	dynamic var setOfStrings: Set<String> = []
	dynamic var set: Set<ObjectWithString> = []
	dynamic var optionalSet: Set<String>!
	dynamic var dictionary: [String: String] = ["foo": "bar"]
	dynamic var optionalDictionary: [String: String]!
	dynamic var optionalObject: ObjectWithString!
	dynamic var optionalComputedObject: ObjectWithString! {
		return ObjectWithString()
	}
	dynamic var computedArray: [ObjectWithString] {
		return [ObjectWithString]()
	}
	dynamic var computedOptionalArray: [ObjectWithString]! {
		return [ObjectWithString]()
	}
}
