//
//  TypeFilteringActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit.UIActivity

protocol ActivityItemsFilter {
	func canPerformWithActivityItems(_ activityItems: [Any]) -> Bool
	func prepareWithActivityItems(_ activityItems: [Any])
}

class TypeBasedActivityItemsFilter<T> : ActivityItemsFilter {
	var acceptedItems: [T]! = nil
	func canPerformWithActivityItems(_ activityItems: [Any]) -> Bool {
		let acceptableItems = filterObjectsByType(activityItems) as [T]
		return acceptableItems.count != 0
	}
	func prepareWithActivityItems(_ activityItems: [Any]) {
		let acceptableItems = filterObjectsByType(activityItems) as [T]
		self.acceptedItems = acceptableItems
	}
}

class TypeFilteringActivity : UIActivity {
	let untypedItemsFilter: ActivityItemsFilter
	override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		return untypedItemsFilter.canPerformWithActivityItems(activityItems)
	}
	override func prepare(withActivityItems activityItems: [Any]) {
		untypedItemsFilter.prepareWithActivityItems(activityItems)
	}
	init(untypedItemsFilter: ActivityItemsFilter) {
		self.untypedItemsFilter = untypedItemsFilter
		super.init()
	}
}

