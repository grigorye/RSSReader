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

public class Item : NSManagedObject {
	typealias _Self = Item
    @NSManaged public var id: String
	@NSManaged public var date: Date
	@NSManaged public var author: String
	@NSManaged public var updatedDate: Date?
	@NSManaged public var pendingUpdateDate: Date?
	@NSManaged public var loadDate: Date
	@NSManaged public var lastOpenedDate: Date?
    @NSManaged public var titleData: NSData
    public var title: String {
		set {
			let bytes = Array(newValue.utf16)
			titleData = NSData(bytes: bytes, length: bytes.count * MemoryLayout<unichar>.stride)
		}
		get {
			let data = titleData
			return String(utf16CodeUnitsNoCopy: unsafeBitCast(data.bytes, to: UnsafePointer<unichar>.self), count: data.length / MemoryLayout<unichar>.stride, freeWhenDone: false)
		}
	}
    @NSManaged public var summaryData: NSData
    public var summary: String? {
		set {
			let bytes = Array(newValue!.utf16)
			summaryData = NSData(bytes: bytes, length: bytes.count * MemoryLayout<unichar>.stride)
		}
		get {
			let data = summaryData
			return String(utf16CodeUnitsNoCopy: unsafeBitCast(data.bytes, to: UnsafePointer<unichar>.self), count: data.length / MemoryLayout<unichar>.stride, freeWhenDone: false)
		}
	}
	@NSManaged public var categories: Set<Folder>
	@NSManaged public var categoriesToBeExcluded: Set<Folder>
	@NSManaged public var categoriesToBeIncluded: Set<Folder>
	@NSManaged public var subscription: Subscription
	@NSManaged public var canonical: [[String : String]]?
	
	static private let initializeOnce: Void = {
		if _0 {
			cachePropertyWithName(_Self.self, name: #keyPath(markedAsRead))
			cachePropertyWithName(_Self.self, name: #keyPath(markedAsFavorite))
		}
	}()
	override public class func initialize() {
		super.initialize()
		_ = initializeOnce
	}
}

extension Item {
	var shortID: UInt64 {
		let scanner = Scanner(string: id.components(separatedBy: "/").last!)
		var shortID = UInt64(0)
		guard scanner.scanHexInt64(&shortID) else {
			fatalError()
		}
		return shortID
	}
}

extension Item : DefaultSortable {
	public static func defaultSortDescriptor() -> NSSortDescriptor {
		return NSSortDescriptor(key: #keyPath(date), ascending: false)
	}
}
