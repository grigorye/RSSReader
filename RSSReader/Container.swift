//
//  Container.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

class Container: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var unreadCount: Int32
    @NSManaged var newestItemDate: NSDate
}
