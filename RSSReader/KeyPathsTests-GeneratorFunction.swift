//
//  KeyPathsTests-GeneratorFunction.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReader
import XCTest
import Foundation

extension KeyPathsTests {
	func testGeneratorFunction() {
#if false
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
#endif
		XCTAssertEqual(objectAndKeyPath(self){"string"}.keyPath, "string")
		XCTAssertEqual(objectAndKeyPath(self){"optionalString"}.keyPath, "optionalString")
		XCTAssertEqual(objectAndKeyPath(self){"array"}.keyPath, "array")
		XCTAssertEqual(objectAndKeyPath(self){"optionalArray"}.keyPath, "optionalArray")
		XCTAssertEqual(objectAndKeyPath(self){"computedArray"}.keyPath, "computedArray")
		XCTAssertEqual(objectAndKeyPath(self){"setOfStrings"}.keyPath, "setOfStrings")
		XCTAssertEqual(objectAndKeyPath(self){"set"}.keyPath, "set")
		XCTAssertEqual(objectAndKeyPath(self){"optionalSet"}.keyPath, "optionalSet")
		XCTAssertEqual(objectAndKeyPath(self){"dictionary"}.keyPath, "dictionary")
		XCTAssertEqual(objectAndKeyPath(self){"optionalDictionary"}.keyPath, "optionalDictionary")
		XCTAssertEqual(objectAndKeyPath(self){"optionalObject.string"}.keyPath, "optionalObject.string")
		XCTAssertEqual(objectAndKeyPath(self){"optionalComputedObject.string"}.keyPath, "optionalComputedObject.string")
		XCTAssertEqual(objectAndKeyPath(self){"optionalComputedObject.optionalAnotherObject.computedLength"}.keyPath, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(objectAndKeyPath(self.optionalObject){"string"}.keyPath, "string")
#if false
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
#endif
	}
}
