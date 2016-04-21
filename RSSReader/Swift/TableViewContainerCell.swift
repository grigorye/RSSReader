//
//  TableViewContainerCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import GEKeyPaths
import UIKit

class TableViewContainerCell : UITableViewCell {
	var unreadCountKVOBinding: KVOBinding!
	func setFromContainer(container: Container) {
		self.unreadCountKVOBinding = KVOBinding(container•{$0.unreadCount}, options: NSKeyValueObservingOptions.Initial) {[unowned self] change in
			self.detailTextLabel?.text = (0 < container.unreadCount) ? "\(container.unreadCount)" : ""
		}
	}
	override func prepareForReuse() {
		self.unreadCountKVOBinding = nil
		super.prepareForReuse()
	}
}
