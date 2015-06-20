//
//  RSSReaderUITests.swift
//  RSSReaderUITests
//
//  Created by Grigory Entin on 15.06.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import XCTest

class RSSReaderUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
		XCUIApplication().tables.staticTexts["Subscriptions"].tap()
		XCUIApplication().navigationBars["News"].buttons["Refresh"].tap()
		
    }
    
}
