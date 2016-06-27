//
//  AddToFavoritesActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit

class AddToFavoritesActivity : TypeFilteringActivity  {
	override func perform() {
		let item = acceptedItems.last!
		item.markedAsFavorite = true
	}
	override func activityType() -> String {
		return "\(applicationDomain).addToFavorites"
	}
	override func activityTitle() -> String {
		return NSLocalizedString("Add to Favorites", comment: "")
	}
	override func activityImage() -> UIImage? {
		return UIImage(named: "AppIcon")
	}
	override class func activityCategory() -> UIActivityCategory {
		return .action
	}
	// MARK: -
	typealias ItemType = Item
	var itemsFilter = TypeBasedActivityItemsFilter<ItemType>()
	var acceptedItems: [ItemType] {
		return itemsFilter.acceptedItems
	}
	init(_: Void) {
		super.init(untypedItemsFilter: self.itemsFilter)
	}
}