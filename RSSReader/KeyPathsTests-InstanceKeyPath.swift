//
//  KeyPathsTests-InstanceKeyPath.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReader
import XCTest
import Foundation

extension KeyPathsTests {
	func testInstanceKeyPath() {
		let oldKeyPathRecordingProxyLiveCount = keyPathRecordingProxyLiveCount
		XCTAssertEqual(instanceKeyPath(self){$0.string}, "string")
		XCTAssertEqual(instanceKeyPath(self){$0.optionalString}, "optionalString")
		XCTAssertEqual(instanceKeyPath(self){$0.array}, "array")
		XCTAssertEqual(instanceKeyPath(self){$0.optionalArray}, "optionalArray")
		XCTAssertEqual(instanceKeyPath(self){$0.computedArray}, "computedArray")
		XCTAssertEqual(instanceKeyPath(self){$0.optionalObject.string}, "optionalObject.string")
		XCTAssertEqual(instanceKeyPath(self){$0.optionalComputedObject.string}, "optionalComputedObject.string")
		XCTAssertEqual(instanceKeyPath(self){$0.optionalComputedObject.optionalAnotherObject.computedLength}, "optionalComputedObject.optionalAnotherObject.computedLength")
		XCTAssertEqual(keyPathRecordingProxyLiveCount, oldKeyPathRecordingProxyLiveCount)
	}
}
