//
//  Folder.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

class Folder: Container {
	@NSManaged var childContainers: NSOrderedSet
	@NSManaged var items: NSSet
	var itemsArray: [Item] {
		return items.allObjects as [Item]
	}
	var mutableItems: NSMutableSet {
		return mutableSetValueForKey("items")
	}
}
