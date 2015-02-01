//
//  TypeFilteringActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit.UIActivity

protocol ActivityItemsFilter {
	func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool
	func prepareWithActivityItems(activityItems: [AnyObject])
}

class TypeBasedActivityItemsFilter<T: AnyObject> : ActivityItemsFilter {
	var acceptedItems: [T]! = nil
	func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
		let acceptableItems = filterObjectsByType(activityItems) as [T]
		return acceptableItems.count != 0
	}
	func prepareWithActivityItems(activityItems: [AnyObject]) {
		let acceptableItems = filterObjectsByType(activityItems) as [T]
		self.acceptedItems = acceptableItems
	}
}

class TypeFilteringActivity : UIActivity {
	var untypedItemsFilter : ActivityItemsFilter!
	override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
		return untypedItemsFilter.canPerformWithActivityItems(activityItems)
	}
	override func prepareWithActivityItems(activityItems: [AnyObject]) {
		untypedItemsFilter.prepareWithActivityItems(activityItems)
	}
	init(untypedItemsFilter: ActivityItemsFilter) {
		self.untypedItemsFilter = untypedItemsFilter
		super.init()
	}
}

