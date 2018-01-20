//
//  RSSReaderUITests.swift
//  RSSReaderUITests
//
//  Created by Grigory Entin on 15.06.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import XCTest

class RSSReaderUITests : RSSReaderUITestsBase {

	var app = XCUIApplication()
	lazy var tablesQuery: XCUIElementQuery = self.app.tables
	lazy var backButton: XCUIElement = self.app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)
	
	var isAtHome: Bool {
		return tablesQuery.staticTexts["Subscriptions-AI"].exists
	}
	
    func pushAndPopHomeItemWithAI(_ itemAI: String) {
		let homeItem = tablesQuery.staticTexts[itemAI]
		homeItem.tap()
		backButton.tap()
		XCTAssert(isAtHome)
	}
	
	func pushToFirstStreamInSubscriptions() {
		let subscriptionsItem = tablesQuery.staticTexts["Subscriptions-AI"]
		subscriptionsItem.tap()
		while 0 < tablesQuery.count {
			tablesQuery.cells.element(boundBy: 0).tap()
		}
		XCTAssert(!isAtHome)
	}
	
	func popToRoot() {
		while !isAtHome {
			backButton.tap()
		}
	}
	
	// MARK:-
	
	func repeatForTesting(_ block: () -> ()) {
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
}
