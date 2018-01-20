//
//  TestsGlobals.swift
//  RSSReaderUITests
//
//  Created by Grigorii Entin on 20/01/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import XCTest

let app = XCUIApplication()
let tablesQuery = app.tables
let backButton = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

extension TestsBase {
	
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
}

extension TestsBase {
	
	func repeatForTesting(_ block: () -> ()) {
		for _ in 0..<5 {
			block()
		}
	}
}
