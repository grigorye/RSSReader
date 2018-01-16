//
//  DataEnabledTestCase.swift
//  GEXCTest
//
//  Created by Grigory Entin on 16.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

@testable import RSSReaderData
import GECoreData
import XCTest
import CoreData

class DataEnabledTestCase : XCTestCase {
	
	private var initX: () = {
		defaults.backgroundImportEnabled = true
		defaults.persistentContainerEnabled = true
	}()
	
	lazy private (set) var dataGenerator: DataGenerator! = DataGenerator()
	
	func setUpCustomDirectoryForPersistentContainer() {
		
		let fileManager = FileManager.default
		let customDirectoryName = "\(self)-\(NSUUID().uuidString)"
		let customDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(customDirectoryName)
		try! fileManager.createDirectory(at: customDirectoryURL, withIntermediateDirectories: true)
		
		if _0 {
			_ = type(of: rssData.persistentContainer).customDirectoryURL
		}
		
		PersistentContainerWithCustomDirectory.customDirectoryURL = customDirectoryURL
		_ = x$(customDirectoryURL)
	}
	
	func setUpPersistentContainer() {
		
		assert(defaults.persistentContainerEnabled)
		
		let persistentContainer = rssData.persistentContainer
		persistentContainer.persistentStoreDescriptions.forEach {
			$0.shouldAddStoreAsynchronously = false
		}
		persistentContainer.loadPersistentStores(completionHandler: { (_, error) in
			
			XCTAssertNil(error)
		})
	}
	
	override func setUp() {
		
		super.setUp()
		
		setUpCustomDirectoryForPersistentContainer()
		setUpPersistentContainer()
	}
	
	override func tearDown() {
		
		dataGenerator = nil
		rssDataImp = nil
		
		super.tearDown()
	}
}
