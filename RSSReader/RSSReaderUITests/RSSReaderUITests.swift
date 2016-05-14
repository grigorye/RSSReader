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

	var app = XCUIApplication()
	lazy var tablesQuery: XCUIElementQuery = self.app.tables
	lazy var backButton: XCUIElement = self.app.navigationBars.elementBoundByIndex(0).buttons.elementBoundByIndex(0)
	
	var isAtHome: Bool {
		return tablesQuery.staticTexts["Subscriptions-AI"].exists
	}
	
    func pushAndPopHomeItemWithAI(itemAI: String) {
		let homeItem = tablesQuery.staticTexts[itemAI]
		homeItem.tap()
		backButton.tap()
		XCTAssert(isAtHome)
	}
	
	func pushToFirstStreamInSubscriptions() {
		let subscriptionsItem = tablesQuery.staticTexts["Subscriptions-AI"]
		subscriptionsItem.tap()
		while 0 < tablesQuery.count {
			tablesQuery.cells.elementBoundByIndex(0).tap()
		}
		XCTAssert(!isAtHome)
	}
	
	func popToRoot() {
		while !isAtHome {
			backButton.tap()
		}
	}
	
	// MARK:-
	
	func repeatForTesting(@noescape block: () -> ()) {
		for _ in 0..<5 {
			block()
		}
	}
	
	// MARK:-

	func testOpenHistory() {
		pushAndPopHomeItemWithAI("History-AI")
	}
	
	func testOpenSubscriptions() {
		pushAndPopHomeItemWithAI("Subscriptions-AI")
	}

	func notestOpenFavorites() {
		pushAndPopHomeItemWithAI("Favorites-AI")
	}
	
	func testOpenItemInStreamInSubscriptions() {
		pushToFirstStreamInSubscriptions()
		popToRoot()
	}

	// MARK:-
	
	func testRepeatOpenHistory() {
		repeatForTesting { pushAndPopHomeItemWithAI("History-AI") }
	}
	
	func testRepeatOpenSubscriptions() {
		repeatForTesting { pushAndPopHomeItemWithAI("Subscriptions-AI") }
	}

	func notestRepeatOpenFavorites() {
		repeatForTesting { pushAndPopHomeItemWithAI("Favorites-AI") }
	}
	
	func testRepeatOpenItemInStreamInSubscriptions() {
		repeatForTesting { testOpenItemInStreamInSubscriptions() }
	}
	
	// MARK:-
	
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
		print(app.debugDescription)
    }
    
    override func tearDown() {
        super.tearDown()
    }

}
