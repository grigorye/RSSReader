//
//  GeneratedDataTests.swift
//  RSSReaderDataTests
//
//  Created by Grigory Entin on 15.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

@testable import RSSReaderData
import XCTest

class GeneratedDataTests : DataEnabledTestCase {
	
	func testNewFolder() {
		
		_ = dataGenerator.newFolder(withName: "Foo")
		
		XCTAssertNoThrow({
			
			try mainQueueManagedObjectContext.save()
		})
	}
}
