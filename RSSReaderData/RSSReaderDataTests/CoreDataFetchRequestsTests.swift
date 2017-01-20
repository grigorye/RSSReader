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

class CoreDataFetchRequestsTests: XCTestCase {
	let rssSession = RSSSession(loginAndPassword: LoginAndPassword(login: "cake218@icloud.com", password: "7L3-Skb-nJ2-Dh2"))
	// MARK: -
    override func setUp() {
    	let authenticateDidComplete = self.expectation(description: "authenticateDidComplete")
		defaults.forceStoreRemoval = true
		firstly {
			return rssSession.authenticate()
		}.then {
			authenticateDidComplete.fulfill()
		}.catch { error in
			XCTFail("error: \(error)")
		}
		self.waitForExpectations(timeout: 5) { error in
			$(error)
		}
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }
	// MARK: -
    func testPullTags() {
		$(mainQueueManagedObjectContext.persistentStoreCoordinator)
    	let pullTagsComplete = self.expectation(description: "pullTagsComplete")
		firstly {
			return rssSession.pullTags()
		}.then {
			pullTagsComplete.fulfill()
		}.catch { error in
			XCTFail("error: \(error)")
		}
		self.waitForExpectations(timeout: 5) { error in
			$(error)
		}
	}
    func testPullTagsFromLastData() {
		$(mainQueueManagedObjectContext.persistentStoreCoordinator)
		_ = try! Data(contentsOf: lastTagsFileURL)
    	let pullTagsComplete = self.expectation(description: "pullTagsComplete")
		firstly {
			return rssSession.pullTags()
		}.then {
			pullTagsComplete.fulfill()
		}.catch { error in
			XCTFail("error: \(error)")
		}
		self.waitForExpectations(timeout: 5) { error in
			$(error)
		}
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
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
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
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
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlock() {
    	let didPerformBlock = self.expectation(description: "didPerformBlock")
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
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
		self.waitForExpectations(timeout: 5) { error in
			$(error)
		}
	}
	func testFetchRequestInPerformBlockInBackgroundQueueContextWithAccessFetchedResultInPerformBlockAndWait() {
    	let didPerformBlockAndWait = self.expectation(description: "didPerformBlockAndWait")
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
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
		self.waitForExpectations(timeout: 5) { error in
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
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))
	}
}
