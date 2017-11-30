//
//  Subscription.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

public class Subscription: Container, Titled {
	@NSManaged public var title: String
    @NSManaged public var htmlURL: NSURL?
    @NSManaged public var iconURL: URL?
    @NSManaged public var url: NSURL?
	@NSManaged var categories: Set<Folder>
	public var visibleTitle: String? {
		return title
	}
}
