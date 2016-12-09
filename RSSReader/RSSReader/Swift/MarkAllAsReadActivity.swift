//
//  MarkAllAsReadActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import class GEUIKit.TypeFilteringActivity
import class GEUIKit.TypeBasedActivityItemsFilter
import UIKit

class MarkAllAsReadActivity : TypeFilteringActivity {
	override func perform() {
		let folder = acceptedItems.last!
		let items = (folder as! ItemsOwner).ownItems
		for i in items {
			i.markedAsRead = true
		}
		rssSession!.markAllAsRead(folder).catch { error in
			$(error)
		}
	}
	override var activityType: UIActivityType {
		return UIActivityType(rawValue: "\(applicationDomain).markAllAsRead")
	}
	override var activityTitle: String {
		return NSLocalizedString("Mark All as Read", comment: "")
	}
	override var activityImage: UIImage? {
		return UIImage(named: "AppIcon")
	}
	override class var activityCategory: UIActivityCategory {
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
