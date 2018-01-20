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

typealias _Self = ItemListScrollingTests
class ItemListScrollingTests : XCTestCase {

	func testScrollingPerformance() {
	
		tablesQuery.staticTexts["Subscriptions-AI"].tap()
		
		measure {
			app.navigationBars["Subscriptions"].buttons["Combined-AI"].tap()
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
			"-stateRestorationEnabled", "NO",
			"-begEndBarButtonItemsEnabled", "YES"
		]
		
		do {
			let fileManager = FileManager.default
			let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			let bundle = Bundle(for: _Self.self)
			let xcappdataURL = bundle.url(forResource: "populated", withExtension: "xcappdata")!
			let xcappdataCopyURL = temporaryDirectoryURL.appendingPathComponent(xcappdataURL.lastPathComponent)
			try? fileManager.removeItem(at: xcappdataCopyURL)
			try! fileManager.copyItem(at: xcappdataURL, to: xcappdataCopyURL)
			let homeURL = xcappdataCopyURL.appendingPathComponent("AppData")
			XCTAssert(try! homeURL.checkResourceIsReachable())
			
			app.launchEnvironment["HOME"] = homeURL.path
			app.launchEnvironment["CFFIXED_USER_HOME"] = homeURL.path
		}

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
    }
	
	var blocksForTearDown = [Handler]()
	
    override func tearDown() {
		blocksForTearDown.forEach {$0()}
		blocksForTearDown = []
        super.tearDown()
    }
	
}
