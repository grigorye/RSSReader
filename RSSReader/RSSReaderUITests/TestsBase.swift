//
//  RSSReaderUITestsBase.swift
//  RSSReaderUITests
//
//  Created by Grigorii Entin on 20/01/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GEFoundation
import XCTest

typealias _Self = TestsBase
class TestsBase : XCTestCase {
	
	func adjustLaunchArguments() {
		app.launchArguments += [
			"-traceEnabled", "NO",
			"-stateRestorationEnabled", "NO",
		]
	}
	
	private func setUpLaunchArguments() {
		
		let savedLaunchArguments = app.launchArguments
		
		adjustLaunchArguments()
		
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
			blocksForTearDown.append {
				app.launchArguments = savedLaunchArguments
			}
		}
	}
	
	override func setUp() {
		super.setUp()
		setUpLaunchArguments()
		
		continueAfterFailure = false
		
		app.launch()
	}
	
	private var blocksForTearDown = [Handler]()
	
	override func tearDown() {
		blocksForTearDown.forEach {$0()}
		blocksForTearDown = []
		super.tearDown()
	}
}
