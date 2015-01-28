//
//  OpenWebPageActivitiy.swift
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import Foundation

class AddToFavoritesActivity : UIActivity {
	override func activityType() -> String {
		return "com.grigoryentin.RSSReader.addToFavorites"
	}
	override func activityTitle() -> String {
		return NSLocalizedString("Add to Favorites", comment: "")
	}
	override func activityImage() -> UIImage? {
		return UIImage(named: "AppIcon")
	}
	override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
		let acceptableItems = filter(activityItems) { nil != ($0 as? Item) }
		return acceptableItems.count != 0
	}
	var acceptableItems: [Item]!
	override func prepareWithActivityItems(activityItems: [AnyObject]) {
		let acceptableItems = activityItems.reduce([Item]()) {
			if let x = $1 as? Item {
				return $0 + [x]
			}
			else {
				return $0
			}
		}
		self.acceptableItems = acceptableItems
	}
	override func performActivity() {
		let item = acceptableItems.last!
		item.markedAsFavorite = true
		self.rssSession.uploadTag(canonicalFavoriteTag, mark: true, forItem: item, completionHandler: { uploadFavoritesStateError in
			if let uploadFavoritesStateError = uploadFavoritesStateError {
				trace("uploadFavoritesStateError", uploadFavoritesStateError)
			}
		})
	}
	override class func activityCategory() -> UIActivityCategory {
		return .Action
	}
}
