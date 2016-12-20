//
//  TableViewContainerCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

extension KVOCompliantUserDefaults {
	@NSManaged var showOwnItemsCount: Bool
}

class TableViewContainerCell : UITableViewCell {
	var unreadCountKVOBinding: KVOBinding!
	func setFromContainer(_ container: Container) {
		self.unreadCountKVOBinding = KVOBinding(container•#keyPath(Container.unreadCount), options: .initial) {[unowned self] change in
			let labelText: String = {
				let nullableUnreadCountText: String? = (0 < container.unreadCount) ? "\(container.unreadCount)" : nil
				guard defaults.showOwnItemsCount else {
					return nullableUnreadCountText ?? ""
				}
				let ownItemsCountText = "[\(container.ownItems.count)]"
				guard let unreadCountText = nullableUnreadCountText else {
					return ownItemsCountText
				}
				return ownItemsCountText + " " + unreadCountText
			}()
			self.detailTextLabel?.text = labelText
		}
	}
	override func prepareForReuse() {
		self.unreadCountKVOBinding = nil
		super.prepareForReuse()
	}
}
