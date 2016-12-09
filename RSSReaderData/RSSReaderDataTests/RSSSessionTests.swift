//
//  RSSSessionTests.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 08.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

@testable import RSSReaderData
import XCTest

class RSSSessionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
		let loginAndPassword = LoginAndPassword(login: "x", password: "y")
		let session = RSSSession(loginAndPassword: loginAndPassword)
		$(session)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
