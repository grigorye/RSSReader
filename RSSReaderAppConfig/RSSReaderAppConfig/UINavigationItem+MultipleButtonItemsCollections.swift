//
//  UINavigationItem+MultipleButtonItemsCollections.swift
//  RSSReader
//
//  Created by Grigory Entin on 16/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import UIKit

extension UINavigationItem {
	@IBOutlet var rightBarButtonItemsCollection: [UIBarButtonItem]? {
		get {
			return self.rightBarButtonItems
		}
		set {
			self.rightBarButtonItems = newValue?.sorted { $0.tag < $1.tag }
		}
	}
	@IBOutlet var leftBarButtonItemsCollection: [UIBarButtonItem]? {
		get {
			return self.leftBarButtonItems
		}
		set {
			self.leftBarButtonItems = newValue?.sorted { $0.tag < $1.tag }
		}
	}
}
