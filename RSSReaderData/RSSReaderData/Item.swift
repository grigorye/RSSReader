//
//  Item.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import func GEFoundation.cachePropertyWithName
import Foundation
import CoreData

public class Item : NSManagedObject {
	typealias _Self = Item
	#if false
	@NSManaged public var json: [String : Any]!
	#else
	@NSManaged public var categoryIDsJson: String?
	#endif
    @NSManaged public var id: String
	@NSManaged public var date: Date
	@NSManaged public var author: String
	@NSManaged public var updatedDate: Date?
	@NSManaged public var pendingUpdateDate: Date?
	@NSManaged public var lastOpenedDate: Date?
    @NSManaged public var titleData: NSData
	@NSManaged public var titleUnoptimized: String
    public var title: String {
		set {
			let bytes = Array(newValue.utf16)
			titleData = NSData(bytes: bytes, length: bytes.count * MemoryLayout<unichar>.stride)
			titleUnoptimized = newValue
		}
		get {
			let data = titleData
			return String(utf16CodeUnitsNoCopy: data.bytes.assumingMemoryBound(to: unichar.self), count: data.length / MemoryLayout<unichar>.stride, freeWhenDone: false)
		}
	}
    @NSManaged public var summaryData: NSData
    @NSManaged public var summaryUnoptimized: String
    public var summary: String? {
		set {
			let bytes = Array(newValue!.utf16)
			summaryData = NSData(bytes: bytes, length: bytes.count * MemoryLayout<unichar>.stride)
			summaryUnoptimized = newValue!
		}
		get {
			let data = summaryData
			return String(utf16CodeUnitsNoCopy: data.bytes.assumingMemoryBound(to: unichar.self), count: data.length / MemoryLayout<unichar>.stride, freeWhenDone: false)
		}
	}
	@NSManaged public var categoryItems: Set<CategoryItem>
	@NSManaged public var categoriesToBeExcluded: Set<Folder>
	@NSManaged public var categoriesToBeIncluded: Set<Folder>
	@NSManaged public var subscription: Subscription
	#if false
	@NSManaged public var canonical: [[String : String]]?
	#else
	@NSManaged public var firstCanonicalHref: String
	#endif

	static private let initializeOnce: Ignored = {
		if _0 {
			cachePropertyWithName(_Self.self, name: #keyPath(markedAsRead))
			cachePropertyWithName(_Self.self, name: #keyPath(markedAsFavorite))
		}
		return Ignored()
	}()
	public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		_ = Item.initializeOnce
		super.init(entity: entity, insertInto: context)
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
	
	public var articleURL: URL {
		
		return URL(string: firstCanonicalHref)!
	}
}

extension Item : DefaultSortable {
	public static func defaultSortDescriptor() -> NSSortDescriptor {
		return NSSortDescriptor(key: #keyPath(date), ascending: false)
	}
}
