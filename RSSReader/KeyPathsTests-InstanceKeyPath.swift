//
//  KeyPathsTests-InstanceKeyPath.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import XCTest
import Foundation

extension KeyPathsTests {
	func testInstanceKeyPath() {
#if false
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
#endif
		XCTAssertEqual(instanceKeyPath(self){"string"}, "string")
		XCTAssertEqual(instanceKeyPath(self){"optionalString"}, "optionalString")
		XCTAssertEqual(instanceKeyPath(self){"array"}, "array")
		XCTAssertEqual(instanceKeyPath(self){"optionalArray"}, "optionalArray")
		XCTAssertEqual(instanceKeyPath(self){"setOfStrings"}, "setOfStrings")
		XCTAssertEqual(instanceKeyPath(self){"set"}, "set")
		XCTAssertEqual(instanceKeyPath(self){"optionalSet"}, "optionalSet")
		XCTAssertEqual(instanceKeyPath(self){"dictionary"}, "dictionary")
		XCTAssertEqual(instanceKeyPath(self){"optionalDictionary"}, "optionalDictionary")
		XCTAssertEqual(instanceKeyPath(self){"computedArray"}, "computedArray")
		XCTAssertEqual(instanceKeyPath(self){"optionalObject.string"}, "optionalObject.string")
		XCTAssertEqual(instanceKeyPath(self){"optionalComputedObject.string"}, "optionalComputedObject.string")
		XCTAssertEqual(instanceKeyPath(self){"optionalComputedObject.optionalAnotherObject.computedLength"}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(instanceKeyPath(self.optionalObject){"string"}, "string")
#if false
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
#endif
	}
}
