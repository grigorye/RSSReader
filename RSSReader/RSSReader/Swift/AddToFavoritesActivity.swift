//
//  AddToFavoritesActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import class GEUIKit.TypeFilteringActivity
import class GEUIKit.TypeBasedActivityItemsFilter
import UIKit

class AddToFavoritesActivity : TypeFilteringActivity  {
	override func perform() {
		let item = acceptedItems.last!
		item.markedAsFavorite = true
	}
	override var activityType: UIActivity.ActivityType {
		return UIActivity.ActivityType(rawValue: "\(applicationDomain).addToFavorites")
	}
	override var activityTitle: String {
		return NSLocalizedString("Add to Favorites", comment: "")
	}
	override var activityImage: UIImage? {
		return UIImage(named: "AppIcon")
	}
	override class var activityCategory: UIActivity.Category {
		return .action
	}
	// MARK: -
	typealias ItemType = Item
	var itemsFilter = TypeBasedActivityItemsFilter<ItemType>()
	var acceptedItems: [ItemType] {
		return itemsFilter.acceptedItems
	}
	init() {
		super.init(untypedItemsFilter: self.itemsFilter)
	}
}
