//
//  Item.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

class Item: NSManagedObject {
    @NSManaged var itemID: String
	@NSManaged var date: NSDate
	@NSManaged var loadDate: NSDate
	@NSManaged var lastOpenedDate: NSDate?
    @NSManaged var title: String?
    @NSManaged var summary: String?
	@NSManaged var categories: Set<Folder>
	var mutableCategories: NSMutableSet {
		return mutableSetValueForKey(self••{"categories"})
	}
	@NSManaged var subscription: Subscription
	@NSManaged var canonical: [[String: String]]?
}
