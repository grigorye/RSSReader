//
//  CoreDataFetchRequestsTests.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

@testable import RSSReaderData
import XCTest
import CoreData
import PromiseKit

class CoreDataFetchRequestsTests : DataEnabledTestCase {
	
	override func setUp() {
		
		super.setUp()
		
		_ = dataGenerator.newFolder(withName: "Foo")
		try! mainQueueManagedObjectContext.save()
	}
	
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithDirectAccessFetchedResult() {
		
		let didPerformBlock = self.expectation(description: "didPerformBlock")
		let backgroundQueueManagedObjectContext = rssData.backgroundQueueManagedObjectContext
		backgroundQueueManagedObjectContext.perform {
			defer { didPerformBlock.fulfill() }
			let fetchRequest = Folder.fetchRequestForEntity()
			let objects = try! backgroundQueueManagedObjectContext.fetch(fetchRequest)
			if let folder = objects.last {
				•(folder.sortID)
			}
			else {
				XCTAssertTrue(false)
			}
		}
		self.waitForExpectations(timeout: 5) { error in
			x$(error)
		}
	}
	
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithFetchedResultAccessedByObjectID() {
		
		let didPerformBlock = self.expectation(description: "didPerformBlock")
		let backgroundQueueManagedObjectContext = rssData.backgroundQueueManagedObjectContext
		backgroundQueueManagedObjectContext.perform {
			defer { didPerformBlock.fulfill() }
			let fetchRequest = NSFetchRequest<NSManagedObjectID>(entityName: Folder.entity().name!)
			fetchRequest.resultType = .managedObjectIDResultType
			let objectIDs = try! backgroundQueueManagedObjectContext.fetch(fetchRequest)
			if let folderObjectID = objectIDs.last {
				let folder = backgroundQueueManagedObjectContext.object(with: folderObjectID) as! Folder
				•(folder.sortID)
			}
			else {
				XCTAssertTrue(false)
			}
		}
		self.waitForExpectations(timeout: 5) { error in
			x$(error)
		}
	}
	
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlock() {
		
		let didPerformBlock = self.expectation(description: "didPerformBlock")
		let backgroundQueueManagedObjectContext = rssData.backgroundQueueManagedObjectContext
		backgroundQueueManagedObjectContext.perform {
			let fetchRequest = Folder.fetchRequestForEntity()
			let objects = try! backgroundQueueManagedObjectContext.fetch(fetchRequest)
			if let folder = objects.last {
				backgroundQueueManagedObjectContext.perform {
					•(folder.sortID)
					didPerformBlock.fulfill()
				}
			}
			else {
				XCTAssertTrue(false)
				didPerformBlock.fulfill()
			}
		}
		self.waitForExpectations(timeout: 5) { error in
			x$(error)
		}
	}
	
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlockAndWait() {
		
		let didPerformBlockAndWait = self.expectation(description: "didPerformBlockAndWait")
		let backgroundQueueManagedObjectContext = rssData.backgroundQueueManagedObjectContext
		backgroundQueueManagedObjectContext.perform {
			let fetchRequest = Folder.fetchRequestForEntity()
			let objects = try! backgroundQueueManagedObjectContext.fetch(fetchRequest)
			if let folder = objects.last {
				backgroundQueueManagedObjectContext.performAndWait {
					•(folder.sortID)
					didPerformBlockAndWait.fulfill()
				}
			}
			else {
				XCTAssertTrue(false)
			}
		}
		self.waitForExpectations(timeout: 5) { error in
			x$(error)
		}
	}
	
	func testFetchRequestInPerformBlockInMainQueueContext() {
		
		let didPerformBlock = self.expectation(description: "didPerformBlock")
		let mainQueueManagedObjectContext = rssData.mainQueueManagedObjectContext
		mainQueueManagedObjectContext.perform {
			defer { didPerformBlock.fulfill() }
			let fetchRequest = Folder.fetchRequestForEntity()
			let objects = try! mainQueueManagedObjectContext.fetch(fetchRequest)
			if let folder = objects.last {
				•(folder.sortID)
			}
		}
		self.waitForExpectations(timeout: 5) { error in
			x$(error)
		}
	}
}
