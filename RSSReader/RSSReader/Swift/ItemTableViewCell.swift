//
//  ItemTableViewCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 17.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData.NSManagedObjectID
import GEBase

class ItemTableViewCell : SystemLayoutSizeCachingTableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var sourceLabel: UILabel!
	@IBOutlet var readMarkLabel: UILabel!
	@IBOutlet var favoriteMarkLabel: UILabel!
	
	var itemObjectID: NSManagedObjectID!
}
