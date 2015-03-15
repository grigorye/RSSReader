//
//  Container.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

class Container: NSManagedObject {
    @NSManaged var streamID: String
    @NSManaged var unreadCount: Int32
    @NSManaged var newestItemDate: NSDate
    @NSManaged var sortID: Int32
	@NSManaged var parentFolder: Folder?
	@NSManaged var viewStates: Set<ContainerViewState>
}

@objc protocol Titled {
	 var visibleTitle: String? { get }
}

@objc protocol ItemsOwner {
	var ownItems: Set<Item> { get }
}
