//
//  ContainerViewState.swift
//  RSSReader
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData.NSManagedObject

public class ContainerViewState: NSManagedObject {
	@NSManaged public var containerViewPredicate: NSPredicate
    @NSManaged public var continuation: String?
    public var loadError: ErrorType?
    @NSManaged public var loadDate: NSDate?
    @NSManaged public var loadCompleted: Bool
    @NSManaged public var lastLoadedItem: Item?
    @NSManaged public var container: Container?
}
