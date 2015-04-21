//
//  KeyPathsTests-PrefixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReader
import XCTest
import Foundation

extension KeyPathsTests {
	func notestPrefixOperator() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual((••self){$0.string}.keyPath, "string")
		XCTAssertEqual((••self){$0.optionalString}.keyPath, "optionalString")
		XCTAssertEqual((••self){$0.array}.keyPath, "array")
		XCTAssertEqual((••self){$0.optionalArray}.keyPath, "optionalArray")
		XCTAssertEqual((••self){$0.computedArray}.keyPath, "computedArray")
		XCTAssertEqual((••self){$0.set}.keyPath, "set")
		XCTAssertEqual((••self){$0.optionalSet}.keyPath, "optionalSet")
		XCTAssertEqual((••self){$0.dictionary}.keyPath, "dictionary")
		XCTAssertEqual((••self){$0.optionalDictionary}.keyPath, "optionalDictionary")
		XCTAssertEqual((••self){$0.optionalObject.string}.keyPath, "optionalObject.string")
		XCTAssertEqual((••self){$0.optionalComputedObject.string}.keyPath, "optionalComputedObject.string")
		XCTAssertEqual((••self){$0.optionalComputedObject.optionalAnotherObject.computedLength}.keyPath, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual((••self.optionalObject){$0.string}.keyPath, "string")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
}
