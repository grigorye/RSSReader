//
//  ItemTableViewCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 17.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import class GEUIKit.SystemLayoutSizeCachingTableViewCell
import CoreData.NSManagedObjectID
import UIKit

extension TypedUserDefaults {
	@NSManaged var showDates: Bool
	@NSManaged var showUnreadMark: Bool
}

protocol ItemTableViewCellDataBinder {
	func setData(_ data: (item: Item, container: Container, nowDate: Date))
}

class ItemTableViewCell : SystemLayoutSizeCachingTableViewCell, ItemTableViewCellDataBinder {
	@IBOutlet final var titleLabel: UILabel!
	@IBOutlet final var dateLabel: UILabel!
	@IBOutlet final var sourceLabel: UILabel!
	@IBOutlet final var readMarkView: UIView!
	@IBOutlet final var favoriteMarkLabel: UILabel!
	
	final var item: Item!
	final var itemPendingUpdateDate: Date?

	final func setData(_ data: (item: Item, container: Container, nowDate: Date)) {
		let item = data.item
		let container = data.container
		let nowDate = data.nowDate
		defer {
			self.item = item
			self.itemPendingUpdateDate = item.pendingUpdateDate
		}
		guard (self.item != item) || (self.itemPendingUpdateDate != item.pendingUpdateDate) else {
			return
		}
		if let titleLabel = self.titleLabel {
			let text = item.title /*?? (item.id as NSString).lastPathComponent*/
			if text != titleLabel.text {
				titleLabel.text = text
			}
		}
		if let sourceLabel = self.sourceLabel {
			let textNaturalCased: String = {
				let itemAuthor = item.author
				guard (itemAuthor != "") && (container is Subscription) else {
					return item.subscription.title
				}
				return itemAuthor
			}()
			let text = textNaturalCased.lowercased()
			if text != sourceLabel.text {
				sourceLabel.text = text
			}
		}
		if let dateLabel = self.dateLabel, defaults.showDates {
			let text = "\(item.itemListFormattedDate(forNowDate: nowDate))".lowercased()
			if dateLabel.text != text {
				dateLabel.text = text
				if _0 {
				dateLabel.textColor = item.markedAsRead ? nil : UIColor.red
				}
			}
		}
		if let readMarkView = self.readMarkView, defaults.showUnreadMark {
			let alpha = CGFloat(item.markedAsRead ? 0 : 1)
			if readMarkView.alpha != alpha {
				readMarkView.alpha = alpha
			}
		}
		if let favoriteMarkLabel = self.favoriteMarkLabel {
			favoriteMarkLabel.isHidden = !item.markedAsFavorite
		}
	}
}
