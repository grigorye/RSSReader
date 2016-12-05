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

class ItemListScrollingTests: XCTestCase {


	func testScrollingPerformance() {
	
		tablesQuery.staticTexts["Subscriptions-AI"].tap()
		
		measure {
			app.navigationBars["RSSReader.FoldersView"].buttons["Combined-AI"].tap()
			app.toolbars.buttons["ToEnd-AI"].tap()
			backButton.tap()
		}
		
	}
	
	// MARK: -

	func setUpLaunchArguments() {
	
		let savedLaunchArguments = app.launchArguments
		app.launchArguments += [
			"-itemListAccessibilityDisabled", "YES",
			"-traceEnabled", "NO",
			"-loadOnScrollDisabled", "YES",
			"-stateRestorationEnabled", "NO"
		]
		do {
			blocksForTearDown += [{
				app.launchArguments = savedLaunchArguments
			}]
		}
	}
	
    override func setUp() {
        super.setUp()
		setUpLaunchArguments()
		
        continueAfterFailure = false
		
        app.launch()
		print(app.debugDescription)
    }
	
	var blocksForTearDown = [Handler]()
	
    override func tearDown() {
		blocksForTearDown.forEach {$0()}
		blocksForTearDown = []
        super.tearDown()
    }
	
}
