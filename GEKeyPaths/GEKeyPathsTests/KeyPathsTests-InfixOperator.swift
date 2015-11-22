//
//  KeyPathsTests-InfixOperator.swift
//  GEKeyPaths
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import XCTest
import Foundation

extension KeyPathsTests {
#if GETypedKeyPaths
	func testObjectAndKeyPathTypedInfixOperator() {
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
	func testClassTypedInfixOperator() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(keyPathRecordingProxyLiveCount, 0)
		XCTAssertEqual(Self_••{$0.string}, "string")
		XCTAssertEqual(Self_••{$0.optionalString}, "optionalString")
		XCTAssertEqual(Self_••{$0.array}, "array")
		XCTAssertEqual(Self_••{$0.optionalArray}, "optionalArray")
		XCTAssertEqual(Self_••{$0.computedArray}, "computedArray")
		XCTAssertEqual(Self_••{$0.setOfStrings}, "setOfStrings")
		XCTAssertEqual(Self_••{$0.set}, "set")
		XCTAssertEqual(Self_••{$0.optionalSet}, "optionalSet")
		XCTAssertEqual(Self_••{$0.dictionary}, "dictionary")
		XCTAssertEqual(Self_••{$0.optionalDictionary}, "optionalDictionary")
		XCTAssertEqual(Self_••{$0.optionalObject.string}, "optionalObject.string")
		XCTAssertEqual(Self_••{$0.optionalComputedObject.string}, "optionalComputedObject.string")
		XCTAssertEqual(Self_••{$0.optionalComputedObject.optionalAnotherObject.computedLength}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
	func testObjectTypedInfixOperator() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(keyPathRecordingProxyLiveCount, 0)
		XCTAssertEqual(self••{$0.string}, "string")
		XCTAssertEqual(self••{$0.optionalString}, "optionalString")
		XCTAssertEqual(self••{$0.array}, "array")
		XCTAssertEqual(self••{$0.optionalArray}, "optionalArray")
		XCTAssertEqual(self••{$0.computedArray}, "computedArray")
		XCTAssertEqual(self••{$0.setOfStrings}, "setOfStrings")
		XCTAssertEqual(self••{$0.set}, "set")
		XCTAssertEqual(self••{$0.optionalSet}, "optionalSet")
		XCTAssertEqual(self••{$0.dictionary}, "dictionary")
		XCTAssertEqual(self••{$0.optionalDictionary}, "optionalDictionary")
		XCTAssertEqual(self••{$0.optionalObject.string}, "optionalObject.string")
		XCTAssertEqual(self••{$0.optionalComputedObject.string}, "optionalComputedObject.string")
		XCTAssertEqual(self••{$0.optionalComputedObject.optionalAnotherObject.computedLength}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
#endif
#if GEStringKeyPaths
	func testStringObjectAndKeyPathTypedInfixOperator() {
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
	func testStringClassTypedInfixOperator() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(keyPathRecordingProxyLiveCount, 0)
		XCTAssertEqual(Self_••{"string"}, "string")
		XCTAssertEqual(Self_••{"optionalString"}, "optionalString")
		XCTAssertEqual(Self_••{"array"}, "array")
		XCTAssertEqual(Self_••{"optionalArray"}, "optionalArray")
		XCTAssertEqual(Self_••{"computedArray"}, "computedArray")
		XCTAssertEqual(Self_••{"setOfStrings"}, "setOfStrings")
		XCTAssertEqual(Self_••{"set"}, "set")
		XCTAssertEqual(Self_••{"optionalSet"}, "optionalSet")
		XCTAssertEqual(Self_••{"dictionary"}, "dictionary")
		XCTAssertEqual(Self_••{"optionalDictionary"}, "optionalDictionary")
		XCTAssertEqual(Self_••{"optionalObject.string"}, "optionalObject.string")
		XCTAssertEqual(Self_••{"optionalComputedObject.string"}, "optionalComputedObject.string")
		XCTAssertEqual(Self_••{"optionalComputedObject.optionalAnotherObject.computedLength"}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
	func testStringObjectTypedInfixOperator() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(keyPathRecordingProxyLiveCount, 0)
		XCTAssertEqual(self••{"string"}, "string")
		XCTAssertEqual(self••{"optionalString"}, "optionalString")
		XCTAssertEqual(self••{"array"}, "array")
		XCTAssertEqual(self••{"optionalArray"}, "optionalArray")
		XCTAssertEqual(self••{"computedArray"}, "computedArray")
		XCTAssertEqual(self••{"setOfStrings"}, "setOfStrings")
		XCTAssertEqual(self••{"set"}, "set")
		XCTAssertEqual(self••{"optionalSet"}, "optionalSet")
		XCTAssertEqual(self••{"dictionary"}, "dictionary")
		XCTAssertEqual(self••{"optionalDictionary"}, "optionalDictionary")
		XCTAssertEqual(self••{"optionalObject.string"}, "optionalObject.string")
		XCTAssertEqual(self••{"optionalComputedObject.string"}, "optionalComputedObject.string")
		XCTAssertEqual(self••{"optionalComputedObject.optionalAnotherObject.computedLength"}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
#endif
}
