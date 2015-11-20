//
//  KeyPathsTests-InfixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import XCTest
import Foundation

extension KeyPathsTests {
#if GETypedKeyPaths
	func testTypedInfixOperator() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(keyPathRecordingProxyLiveCount, 0)
		XCTAssertEqual((self•{$0.string}).keyPath, "string")
		XCTAssertEqual((self•{$0.optionalString}).keyPath, "optionalString")
		XCTAssertEqual((self•{$0.array}).keyPath, "array")
		XCTAssertEqual((self•{$0.optionalArray}).keyPath, "optionalArray")
		XCTAssertEqual((self•{$0.computedArray}).keyPath, "computedArray")
		XCTAssertEqual((self•{$0.setOfStrings}).keyPath, "setOfStrings")
		XCTAssertEqual((self•{$0.set}).keyPath, "set")
		XCTAssertEqual((self•{$0.optionalSet}).keyPath, "optionalSet")
		XCTAssertEqual((self•{$0.dictionary}).keyPath, "dictionary")
		XCTAssertEqual((self•{$0.optionalDictionary}).keyPath, "optionalDictionary")
		XCTAssertEqual((self•{$0.optionalObject.string}).keyPath, "optionalObject.string")
		XCTAssertEqual((self•{$0.optionalComputedObject.string}).keyPath, "optionalComputedObject.string")
		XCTAssertEqual((self•{$0.optionalComputedObject.optionalAnotherObject.computedLength}).keyPath, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
#endif
#if GEStringKeyPaths
	func testStringInfixOperator() {
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
	}
#endif
}
