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
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(objectAndKeyPath(self){$0.string}.keyPath, "string")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalString}.keyPath, "optionalString")
		XCTAssertEqual(objectAndKeyPath(self){$0.array}.keyPath, "array")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalArray}.keyPath, "optionalArray")
		XCTAssertEqual(objectAndKeyPath(self){$0.computedArray}.keyPath, "computedArray")
		XCTAssertEqual(objectAndKeyPath(self){$0.setOfStrings}.keyPath, "setOfStrings")
		XCTAssertEqual(objectAndKeyPath(self){$0.set}.keyPath, "set")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalSet}.keyPath, "optionalSet")
		XCTAssertEqual(objectAndKeyPath(self){$0.dictionary}.keyPath, "dictionary")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalDictionary}.keyPath, "optionalDictionary")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalObject.string}.keyPath, "optionalObject.string")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalComputedObject.string}.keyPath, "optionalComputedObject.string")
		XCTAssertEqual(objectAndKeyPath(self){$0.optionalComputedObject.optionalAnotherObject.computedLength}.keyPath, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(objectAndKeyPath(self.optionalObject){$0.string}.keyPath, "string")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
}
