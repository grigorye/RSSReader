//
//  MarkAllAsReadActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit

class MarkAllAsReadActivity : TypeFilteringActivity {
	override func perform() {
		let folder = acceptedItems.last!
		let items = (folder as! ItemsOwner).ownItems
		for i in items {
			i.markedAsRead = true
		}
		rssSession!.markAllAsRead(folder) { error in
			$(error)
		}
	}
	override func activityType() -> String {
		return "\(applicationDomain).markAllAsRead"
	}
	override func activityTitle() -> String {
		return NSLocalizedString("Mark All as Read", comment: "")
	}
	override func activityImage() -> UIImage? {
		return UIImage(named: "AppIcon")
	}
	override class func activityCategory() -> UIActivityCategory {
		return .action
	}
	// MARK: -
	typealias FilteredItem = Container
	var itemsFilter = TypeBasedActivityItemsFilter<FilteredItem>()
	var acceptedItems: [FilteredItem] {
		return itemsFilter.acceptedItems
	}
	init(_: Void) {
		super.init(untypedItemsFilter: self.itemsFilter)
	}
}
