//
//  OpenWebPageActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import class GEUIKit.TypeFilteringActivity
import class GEUIKit.TypeBasedActivityItemsFilter
import UIKit

class OpenWebPageActivity : TypeFilteringActivity {
	override func perform() {
		let url = acceptedItems.last!
		let application = UIApplication.shared
		if #available(iOS 10.0, *) {
			application.open(url, options: [:], completionHandler: nil)
		} else {
			application.openURL(url)
		}
	}
	override var activityType: UIActivityType {
		return UIActivityType(rawValue: "\(applicationDomain).openWebPage")
	}
	override var activityTitle: String {
		return NSLocalizedString("Open in Safari", comment: "")
	}
	override var activityImage: UIImage? {
		return UIImage(named: "AppIcon")
	}
	override class var activityCategory: UIActivityCategory {
		return .action
	}
	// MARK: -
	typealias FilteredItem = URL
	var itemsFilter = TypeBasedActivityItemsFilter<FilteredItem>()
	var acceptedItems: [FilteredItem] {
		return itemsFilter.acceptedItems
	}
	init(_: Void) {
		super.init(untypedItemsFilter: self.itemsFilter)
	}
}
