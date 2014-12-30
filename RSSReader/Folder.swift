//
//  Folder.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

class Folder: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var unreadCount: Int32
    @NSManaged var newestItemDate: NSDate
}
