//
//  OpenWebPageActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class OpenWebPageActivity : TypeFilteringActivity {
	override func performActivity() {
		let url = acceptedItems.last!
		UIApplication.sharedApplication().openURL(url)
	}
	override func activityType() -> String {
		return "\(applicationDomain).openWebPage"
	}
	override func activityTitle() -> String {
		return NSLocalizedString("Open in Safari", comment: "")
	}
	override func activityImage() -> UIImage? {
		return UIImage(named: "AppIcon")
	}
	override class func activityCategory() -> UIActivityCategory {
		return .Action
	}
	// MARK: -
	typealias FilteredItem = NSURL
	var itemsFilter = TypeBasedActivityItemsFilter<FilteredItem>()
	var acceptedItems: [FilteredItem] {
		return itemsFilter.acceptedItems
	}
	init(_: Void) {
		super.init(untypedItemsFilter: self.itemsFilter)
	}
}
