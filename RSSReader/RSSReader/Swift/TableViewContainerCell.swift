//
//  TableViewContainerCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
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
				let nullableOwnItemsCountText: String? = {
					guard let itemsOwner = container as? ItemsOwner else {
						return nil
					}
					return "[\(itemsOwner.ownItems.count)]"
				}()
				guard let unreadCountText = nullableUnreadCountText, let ownItemsCountText = nullableOwnItemsCountText else {
					guard let unreadCountText = nullableUnreadCountText else {
						guard let ownItemsCountText = nullableOwnItemsCountText else {
							return ""
						}
						return ownItemsCountText
					}
					return unreadCountText
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
