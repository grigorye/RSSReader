//
//  TableViewContainerCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class TableViewContainerCell : UITableViewCell {
	var unreadCountKVOBinding: KVOBinding!
	func setFromContainer(container: Container) {
		self.unreadCountKVOBinding = KVOBinding(object: container, keyPath: "unreadCount", options: NSKeyValueObservingOptions.Initial) {[unowned self] change in
			self.detailTextLabel?.text = "\(container.unreadCount)"
			return
		}
	}
	override func prepareForReuse() {
		self.unreadCountKVOBinding = nil
		super.prepareForReuse()
	}
}
