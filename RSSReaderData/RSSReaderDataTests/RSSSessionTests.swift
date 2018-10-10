//
//  RSSSessionTests.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 08.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

@testable import RSSReaderData
import Promises
import XCTest
import CoreData

class RSSSessionTests : DataEnabledTestCase {
	
	typealias _Self = RSSSessionTests
	
	static func loginAndPasswordImp() -> LoginAndPassword {
		
		let bundle = Bundle(for: _Self.self)
		let plistURL = bundle.url(forResource: "RSSReaderDataTests-Secrets", withExtension: "plist")!
		let plistData = try! Data(contentsOf: plistURL)
		let plist = try! PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String : String]
		let login = plist["login"]
		let password = plist["password"]
		return LoginAndPassword(login: login, password: password)
	}
	
	static let loginAndPassword: LoginAndPassword = loginAndPasswordImp()
	
	let rssSession = RSSSession(loginAndPassword: loginAndPassword)
	
	// MARK: -
	
	override func setUp() {
		
		super.setUp()
		x$(self)
		let authenticateDidComplete = self.expectation(description: "authenticateDidComplete")
		defaults.forceStoreRemoval = true
		Promise({ [rssSession] in
			return rssSession.authenticate()
		}).then({
			authenticateDidComplete.fulfill()
		}).catch({ error in
			authenticateDidComplete.fulfill()
			XCTFail("error: \(error)")
		})
		self.waitForExpectations(timeout: 10) { error in
			x$(error)
		}
	}
	
	// MARK: -
	
	func testPullTags() {
		
		x$(mainQueueManagedObjectContext.persistentStoreCoordinator)
		
		let pullTagsComplete = self.expectation(description: "pullTagsComplete")
		Promise({ [rssSession] in
			return rssSession.pullTags()
		}).then({
			pullTagsComplete.fulfill()
		}).catch({ error in
			XCTFail("error: \(error)")
		})
		self.waitForExpectations(timeout: 5) { error in
			x$(error)
		}
	}
	
	func testPullTagsFromLastData() {
		
		x$(mainQueueManagedObjectContext.persistentStoreCoordinator)
		let pullTagsComplete = self.expectation(description: "pullTagsComplete")
		Promise({ [rssSession] in
			return rssSession.pullTags()
		}).then({
			pullTagsComplete.fulfill()
		}).catch({ error in
			XCTFail("error: \(error)")
		})
		self.waitForExpectations(timeout: 1) { error in
			x$(error)
		}
	}
	
	func testNewSession() {
		
		let loginAndPassword = LoginAndPassword(login: "x", password: "y")
		let session = RSSSession(loginAndPassword: loginAndPassword)
		x$(session)
	}
}
