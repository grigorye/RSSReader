//
//  ItemListScrollingTests.swift
//  RSSReader
//
//  Created by Grigory Entin on 04.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import XCTest

let app = XCUIApplication()
let tablesQuery = app.tables
let backButton = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

class ItemListScrollingTests : RSSReaderUITestsBase {

	func testScrollingPerformance() {
	
		tablesQuery.staticTexts["Subscriptions-AI"].tap()
		
		measure {
			app.navigationBars["Subscriptions"].buttons["Combined-AI"].tap()
			app.toolbars.buttons["ToEnd-AI"].tap()
			backButton.tap()
		}
	}
	
	override func adjustLaunchArguments() {
		
		super.adjustLaunchArguments()
		
		app.launchArguments += [
			"-itemListAccessibilityDisabled", "YES",
			"-loadOnScrollDisabled", "YES",
			"-begEndBarButtonItemsEnabled", "YES"
		]
	}
}
