//
//  ContainerViewState.swift
//  RSSReader
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData.NSManagedObject

class ContainerViewState: NSManagedObject {
	@NSManaged var containerViewPredicate: NSPredicate
    @NSManaged var continuation: String?
    @NSManaged var loadError: NSError?
    @NSManaged var loadDate: NSDate?
    @NSManaged var loadCompleted: Bool
    @NSManaged var lastLoadedItem: Item?
    @NSManaged var container: Container?
}
