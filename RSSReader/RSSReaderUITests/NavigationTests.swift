//
//  NavigationTests.swift
//  RSSReaderUITests
//
//  Created by Grigory Entin on 15.06.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import XCTest

class NavigationTests : TestsBase {

	// MARK:-

	func testOpenHistory() {
		pushAndPopHomeItemWithAI("History-AI")
	}
	
	func testOpenSubscriptions() {
		pushAndPopHomeItemWithAI("Subscriptions-AI")
	}

	func notestOpenFavorites() {
		pushAndPopHomeItemWithAI("Favorites-AI")
	}
	
	func testOpenItemInStreamInSubscriptions() {
		pushToFirstStreamInSubscriptions()
		popToRoot()
	}

	// MARK:-
	
	func testRepeatOpenHistory() {
		repeatForTesting { pushAndPopHomeItemWithAI("History-AI") }
	}
	
	func testRepeatOpenSubscriptions() {
		repeatForTesting { pushAndPopHomeItemWithAI("Subscriptions-AI") }
	}

	func notestRepeatOpenFavorites() {
		repeatForTesting { pushAndPopHomeItemWithAI("Favorites-AI") }
	}
	
	func testRepeatOpenItemInStreamInSubscriptions() {
		repeatForTesting { testOpenItemInStreamInSubscriptions() }
	}
}
