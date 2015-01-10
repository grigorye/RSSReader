//
//  Subscription.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

class Subscription: Container {
	@NSManaged var title: String?
    @NSManaged var htmlURL: NSURL?
    @NSManaged var iconURL: NSURL?
    @NSManaged var url: NSURL?
	@NSManaged var categories: NSSet
}
