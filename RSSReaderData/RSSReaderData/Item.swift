//
//  Item.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import Foundation
import CoreData

public class Item: NSManagedObject {
    @NSManaged public var itemID: String
	@NSManaged public var date: NSDate
	@NSManaged public var updatedDate: NSDate?
	@NSManaged public var loadDate: NSDate
	@NSManaged public var lastOpenedDate: NSDate?
    @NSManaged public var title: String?
    @NSManaged public var summary: String?
	@NSManaged public var categories: Set<Folder>
	@NSManaged public var subscription: Subscription
	@NSManaged public var canonical: [[String: String]]?
}