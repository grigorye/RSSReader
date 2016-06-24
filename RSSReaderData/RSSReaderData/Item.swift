//
//  Item.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation
import CoreData

public class Item: NSManagedObject {
	typealias _Self = Item
    @NSManaged public var itemID: String
	@NSManaged public var date: Date
	@NSManaged public var author: String
	@NSManaged public var updatedDate: Date?
	@NSManaged public var loadDate: Date
	@NSManaged public var lastOpenedDate: Date?
    @NSManaged public var titleData: NSData
    public var title: String {
		set {
			let bytes = Array(newValue.utf16)
			titleData = NSData(bytes: bytes, length: bytes.count * strideof(unichar))
		}
		get {
			let data = titleData
			return String(utf16CodeUnitsNoCopy: unsafeBitCast(data.bytes, to: UnsafePointer<unichar>.self), count: data.length / strideof(unichar), freeWhenDone: false)
		}
	}
    @NSManaged public var summaryData: NSData
    public var summary: String? {
		set {
			let bytes = Array(newValue!.utf16)
			summaryData = NSData(bytes: bytes, length: bytes.count * strideof(unichar))
		}
		get {
			let data = summaryData
			return String(utf16CodeUnitsNoCopy: unsafeBitCast(data.bytes, to: UnsafePointer<unichar>.self), count: data.length / strideof(unichar), freeWhenDone: false)
		}
	}
	@NSManaged public var categories: Set<Folder>
	@NSManaged public var subscription: Subscription
	@NSManaged public var canonical: [[String: String]]?
	
	private static var registerCachedPropertiesOnce = {
		cachePropertyWithName(_Self.self, name: #keyPath(markedAsRead))
	}
	override public class func initialize() {
		super.initialize()
		if _0 {
			_ = registerCachedPropertiesOnce
		}
	}
}
