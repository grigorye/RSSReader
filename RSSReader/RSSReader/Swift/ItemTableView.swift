//
//  ItemTableView.swift
//  RSSReader
//
//  Created by Grigory Entin on 05.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import UIKit

extension KVOCompliantUserDefaults {

	@NSManaged var itemListAccessibilityDisabled: Bool

}

class ItemTableView : UITableView {

	override func accessibilityElement(at index: Int) -> Any? {
		guard !defaults.itemListAccessibilityDisabled else {
			return nil
		}
		return super.accessibilityElement(at: index)
	}
	
	override func accessibilityElementCount() -> Int {
		guard !defaults.itemListAccessibilityDisabled else {
			return 0
		}
		return super.accessibilityElementCount()
	}
	
}
