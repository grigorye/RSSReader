//
//  KeyPathsTests-InfixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import XCTest
import Foundation

extension KeyPathsTests {
	func testInfixOperator() {
#if false
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(keyPathRecordingProxyLiveCount, 0)
#endif
		XCTAssertEqual((self•{"string"}).keyPath, "string")
		XCTAssertEqual((self•{"optionalString"}).keyPath, "optionalString")
		XCTAssertEqual((self•{"array"}).keyPath, "array")
		XCTAssertEqual((self•{"optionalArray"}).keyPath, "optionalArray")
		XCTAssertEqual((self•{"computedArray"}).keyPath, "computedArray")
		XCTAssertEqual((self•{"setOfStrings"}).keyPath, "setOfStrings")
		XCTAssertEqual((self•{"set"}).keyPath, "set")
		XCTAssertEqual((self•{"optionalSet"}).keyPath, "optionalSet")
		XCTAssertEqual((self•{"dictionary"}).keyPath, "dictionary")
		XCTAssertEqual((self•{"optionalDictionary"}).keyPath, "optionalDictionary")
		XCTAssertEqual((self•{"optionalObject.string"}).keyPath, "optionalObject.string")
		XCTAssertEqual((self•{"optionalComputedObject.string"}).keyPath, "optionalComputedObject.string")
		XCTAssertEqual((self•{"optionalComputedObject.optionalAnotherObject.computedLength"}).keyPath, "optionalComputedObject.optionalAnotherObject.computedLength")
#if false
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
#endif
	}
}
