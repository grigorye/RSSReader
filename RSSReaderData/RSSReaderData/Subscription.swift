//
//  Subscription.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import Foundation
import CoreData

public class Subscription: Container, Titled {
	@NSManaged public var title: String
    @NSManaged public var htmlURL: NSURL?
    @NSManaged public var iconURL: NSURL?
    @NSManaged public var url: NSURL?
	@NSManaged var categories: Set<Folder>
	@NSManaged var items: Set<Item>
	public var visibleTitle: String? {
		return title
	}
}

extension Subscription: ItemsOwner {
	public var ownItems: Set<Item> {
		return items
	}
}