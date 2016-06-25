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
	// MARK: -
    override func setUp() {
    	let authenticateDidComplete = self.expectation(withDescription: "authenticateDidComplete")
		rssSession.authenticate { error in
			XCTAssert(nil == error, "error: \(error)")
			authenticateDidComplete.fulfill()
		}
		self.waitForExpectations(withTimeout: 5) { error in
			$(error)
		}
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }
	// MARK: -
	func testAuthenticate() {
    	let authenticateDidComplete = self.expectation(withDescription: "authenticateDidComplete")
		rssSession.authenticate { error in
			XCTAssert(nil == error, "error: \(error)")
			authenticateDidComplete.fulfill()
		}
		self.waitForExpectations(withTimeout: 5) { error in
			$(error)
		}
	}
    func testUpdateTags() {
		$(mainQueueManagedObjectContext.persistentStoreCoordinator)
    	let updateTagsComplete = self.expectation(withDescription: "updateTagsComplete")
		rssSession.updateTags { error in
			XCTAssert(nil == error, "error: \(error)")
			updateTagsComplete.fulfill()
		}
		self.waitForExpectations(withTimeout: 5) { error in
			$(error)
		}
	}
    func testUpdateTagsFromLastData() {
    	let updateTagsComplete = self.expectation(withDescription: "updateTagsComplete")
		let data = try! Data(contentsOf: lastTagsFileURL)
		rssSession.updateTags(from: data) { error in
			updateTagsComplete.fulfill()
			XCTAssert(nil == error, "error: \(error)")
		}
		self.waitForExpectations(withTimeout: 5) { error in
			$(error)
		}
		RunLoop.current().run(until: Date(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithDirectAccessFetchedResult() {
		backgroundQueueManagedObjectContext.perform {
			let fetchRequest = Folder.fetchRequestForEntity()
			let objects = try! backgroundQueueManagedObjectContext.fetch(fetchRequest)
			if let folder = objects.last {
				•(folder.sortID)
			}
			else {
				XCTAssertTrue(false)
			}
		}
		RunLoop.current().run(until: Date(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithFetchedResultAccessedByObjectID() {
		backgroundQueueManagedObjectContext.perform {
			let fetchRequest = NSFetchRequest<NSManagedObjectID>(entityName: Folder.entityName())
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
		RunLoop.current().run(until: Date(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlock() {
    	let didPerformBlock = self.expectation(withDescription: "didPerformBlock")
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
			}
		}
		RunLoop.current().run(until: Date(timeIntervalSinceNow: 5))
		self.waitForExpectations(withTimeout: 5) { error in
			$(error)
		}
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlockAndWait() {
    	let didPerformBlockAndWait = self.expectation(withDescription: "didPerformBlockAndWait")
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
		RunLoop.current().run(until: Date(timeIntervalSinceNow: 5))
		self.waitForExpectations(withTimeout: 5) { error in
			$(error)
		}
	}
	func testFetchRequestInPerformBlockInMainQueueContext() {
		mainQueueManagedObjectContext.perform {
			let fetchRequest = Folder.fetchRequestForEntity()
			let objects = try! mainQueueManagedObjectContext.fetch(fetchRequest)
			if let folder = objects.last {
				•(folder.sortID)
			}
		}
		RunLoop.current().run(until: Date(timeIntervalSinceNow: 5))
	}
}
