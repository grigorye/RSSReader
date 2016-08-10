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

class TableViewContainerCell : UITableViewCell {
	var unreadCountKVOBinding: KVOBinding!
	func setFromContainer(_ container: Container) {
		self.unreadCountKVOBinding = KVOBinding(container•#keyPath(Container.unreadCount), options: .initial) {[unowned self] change in
			let unreadCountText: String? = (0 < container.unreadCount) ? "\(container.unreadCount)" : nil
			let ownItemsCountText: String? = {
				guard let itemsOwner = container as? ItemsOwner else {
					return nil
				}
				return "[\(itemsOwner.ownItems.count)]"
			}()
			let labelText: String = {
				if let unreadCountText = unreadCountText, let ownItemsCountText = ownItemsCountText {
					return ownItemsCountText + " " + unreadCountText
				}
				if let ownItemsCountText = ownItemsCountText {
					return ownItemsCountText
				}
				if let unreadCountText = unreadCountText {
					return unreadCountText
				}
				return ""
			}()
			self.detailTextLabel?.text = labelText
		}
	}
	override func prepareForReuse() {
		self.unreadCountKVOBinding = nil
		super.prepareForReuse()
	}
}
