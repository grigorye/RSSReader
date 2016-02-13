//
//  CoreDataFetchRequestsTests.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import XCTest
import CoreData
@testable import RSSReaderData
@testable import GEBase

class CoreDataFetchRequestsTests: XCTestCase {
	let rssSession = RSSSession(loginAndPassword: LoginAndPassword(login: "cake218@icloud.com", password: "7L3-Skb-nJ2-Dh2"))

    override func setUp() {
    	let authenticateDidComplete = self.expectationWithDescription("authenticateDidComplete")
		rssSession.authenticate { error in
			XCTAssert(nil == error, "error: \(error)")
			authenticateDidComplete.fulfill()
		}
		self.waitForExpectationsWithTimeout(5) { error in
			$(error)
		}
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }
	func testAuthenticate() {
    	let authenticateDidComplete = self.expectationWithDescription("authenticateDidComplete")
		rssSession.authenticate { error in
			XCTAssert(nil == error, "error: \(error)")
			authenticateDidComplete.fulfill()
		}
		self.waitForExpectationsWithTimeout(5) { error in
			$(error)
		}
	}
    func testUpdateTags() {
		$(mainQueueManagedObjectContext.persistentStoreCoordinator)
    	let updateTagsComplete = self.expectationWithDescription("updateTagsComplete")
		rssSession.updateTags { error in
			XCTAssert(nil == error, "error: \(error)")
			updateTagsComplete.fulfill()
		}
		self.waitForExpectationsWithTimeout(5) { error in
			$(error)
		}
	}
    func testUpdateTagsFromLastData() {
    	let updateTagsComplete = self.expectationWithDescription("updateTagsComplete")
		let data = try! NSData(contentsOfFile: lastTagsDataPath, options: [])
		rssSession.updateTagsFromData(data) { error in
			updateTagsComplete.fulfill()
			XCTAssert(nil == error, "error: \(error)")
		}
		self.waitForExpectationsWithTimeout(5) { error in
			$(error)
		}
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithDirectAccessFetchedResult() {
		backgroundQueueManagedObjectContext.performBlock {
			let fetchRequest = NSFetchRequest(entityName: "Folder")
			let objects = try! backgroundQueueManagedObjectContext.executeFetchRequest(fetchRequest)
			if let folder = objects.last as! Folder? {
				void(folder.sortID)
			}
			else {
				XCTAssertTrue(false)
			}
		}
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithFetchedResultAccessedByObjectID() {
		backgroundQueueManagedObjectContext.performBlock {
			let fetchRequest = NSFetchRequest(entityName: "Folder")
			fetchRequest.resultType = .ManagedObjectIDResultType
			let objectIDs = try! backgroundQueueManagedObjectContext.executeFetchRequest(fetchRequest)
			if let folderObjectID = objectIDs.last as! NSManagedObjectID? {
				let folder = backgroundQueueManagedObjectContext.objectWithID(folderObjectID) as! Folder
				void(folder.sortID)
			}
			else {
				XCTAssertTrue(false)
			}
		}
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlock() {
    	let didPerformBlock = self.expectationWithDescription("didPerformBlock")
		backgroundQueueManagedObjectContext.performBlock {
			let fetchRequest = NSFetchRequest(entityName: "Folder")
			let objects = try! backgroundQueueManagedObjectContext.executeFetchRequest(fetchRequest)
			if let folder = objects.last as! Folder? {
				backgroundQueueManagedObjectContext.performBlock {
					void(folder.sortID)
					didPerformBlock.fulfill()
				}
			}
			else {
				XCTAssertTrue(false)
			}
		}
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
		self.waitForExpectationsWithTimeout(5) { error in
			$(error)
		}
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlockAndWait() {
    	let didPerformBlockAndWait = self.expectationWithDescription("didPerformBlockAndWait")
		backgroundQueueManagedObjectContext.performBlock {
			let fetchRequest = NSFetchRequest(entityName: "Folder")
			let objects = try! backgroundQueueManagedObjectContext.executeFetchRequest(fetchRequest)
			if let folder = objects.last as! Folder? {
				backgroundQueueManagedObjectContext.performBlockAndWait {
					void(folder.sortID)
					didPerformBlockAndWait.fulfill()
				}
			}
			else {
				XCTAssertTrue(false)
			}
		}
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
		self.waitForExpectationsWithTimeout(5) { error in
			$(error)
		}
	}
	func testFetchRequestInPerformBlockInMainQueueContext() {
		mainQueueManagedObjectContext.performBlock {
			let fetchRequest = NSFetchRequest(entityName: "Folder")
			let objects = try! mainQueueManagedObjectContext.executeFetchRequest(fetchRequest)
			if let folder = objects.last as! Folder? {
				void(folder.sortID)
			}
		}
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 5))
	}
}
