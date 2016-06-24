//
//  Folder.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

public class Folder : Container, Titled {
	@NSManaged public var childContainers: OrderedSet
	@NSManaged var items: Set<Item>
	public var visibleTitle: String? {
		return (streamID as NSString).lastPathComponent
	}
}

extension Folder : ItemsOwner {
	public var ownItems: Set<Item> {
		return self.items
	}
}
