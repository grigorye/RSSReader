//
//  CoreData.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

extension Item : ManagedIdentifiable {
	class func entityName() -> String {
		return "Item"
	}
	func importFromJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		let timeIntervalSince1970 = (json["timestampUsec"] as NSString).doubleValue * 1e-6
		self.date = NSDate(timeIntervalSince1970: timeIntervalSince1970)
		self.title = json["title"] as NSString?
		let summary = (json["summary"] as? NSDictionary)?["content"] as NSString?
		self.summary = summary
		let managedObjectContext = self.managedObjectContext!
		let streamID = (json["origin"] as? NSDictionary)?["streamId"] as NSString
		var subscriptionImportError: NSError?
		let subscription = insertedObjectUnlessFetchedWithID(Subscription.self, id: streamID, managedObjectContext: managedObjectContext, error: &subscriptionImportError)!
		self.subscription = subscription
		self.canonical = json["canonical"] as [[String : String]]?
		if let categories = json["categories"] as? [String] {
			for category in categories {
				var categoryImportError: NSError?
				if let folder = insertedObjectUnlessFetchedWithID(Folder.self, id: category, managedObjectContext: managedObjectContext, error: &categoryImportError) {
					folder.id = category
					self.mutableSetValueForKey("categories").addObject(folder)
				}
			}
		}
	}
}
extension Subscription : ManagedIdentifiable {
	override class func entityName() -> String {
		return "Subscription"
	}
	class func sortDescriptorsVariants() -> [[NSSortDescriptor]] {
		return [[NSSortDescriptor(key: "sortID", ascending: true)]]
	}
	override func importFromJson(jsonObject: AnyObject) {
		super.importFromJson(jsonObject)
		let json = jsonObject as [String: AnyObject]
		self.title = json["title"] as NSString?
		self.url = NSURL(string: json["url"] as NSString)
		self.iconURL = NSURL(string: json["iconUrl"] as NSString)
		self.htmlURL = NSURL(string: json["htmlUrl"] as NSString)
		if let categories = json["categories"] as? [[String: AnyObject]] {
			for category in categories {
				let id = category["id"] as String
				var categoryImportError: NSError?
				if let folder = insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: self.managedObjectContext!, error: &categoryImportError) {
					self.mutableSetValueForKey("categories").addObject(folder)
				}
			}
		}
	}
}
extension Container: DefaultSortable {
	class func defaultSortDescriptor() -> NSSortDescriptor {
		return NSSortDescriptor(key: "id", ascending: true)
	}
}
extension Container: ManagedIdentifiable {
	class func entityName() -> String {
		return "Container"
	}
	func importFromJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		let sortIDString = json["sortid"] as String
		var sortIDUnsigned : UInt32 = 0
		if !NSScanner(string: sortIDString).scanHexInt(&sortIDUnsigned) {
			abort()
		}
		let sortID = Int32(bitPattern: sortIDUnsigned)
		self.sortID = trace("sortID", sortID)
	}
	func importFromUnreadCountJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		self.id = json["id"] as NSString
		self.unreadCount = (json["count"] as NSNumber).intValue
		let timeIntervalSince1970 = (json["newestItemTimestampUsec"] as NSString).doubleValue * 1e-9
		self.newestItemDate = NSDate(timeIntervalSince1970: timeIntervalSince1970)
	}
	class func importStreamPreferencesJson(jsonObject: AnyObject, managedObjectContext: NSManagedObjectContext) {
		if let json = jsonObject as? [String : [[String : AnyObject]]] {
			for (folderID, prefs) in json {
				println("folderID: \(folderID), prefs: \(prefs)")
				for prefs in prefs {
					let id = prefs["id"] as? String
					if id == "subscription-ordering" {
						if let value = prefs["value"] as? String {
							println("value: \(value)")
							var insertContainerError: NSError?
							if let folder = insertedObjectUnlessFetchedWithID(Folder.self, id: folderID, managedObjectContext: managedObjectContext, error: &insertContainerError) {
								assert(folder.id == folderID, "")
								let characterCountInValue = countElements(value)
								if characterCountInValue % 8 == 0 {
									var sortIDs = [Int32]()
									for var range = value.startIndex..<advance(value.startIndex, 8); range.endIndex != value.endIndex; range = advance(range.startIndex, 8)..<advance(range.endIndex, 8) {
										let sortIDString = value[range]
										var sortIDUnsigned : UInt32 = 0
										if !NSScanner(string: sortIDString).scanHexInt(&sortIDUnsigned) {
											abort()
										}
										let sortID = Int32(bitPattern: sortIDUnsigned)
										sortIDs += [sortID]
									}
									let request: NSFetchRequest = {
										let $ = NSFetchRequest(entityName: Container.entityName())
										$.predicate = NSPredicate(format: "sortID IN %@", argumentArray: [map(sortIDs) { NSNumber(int: $0) }])
										return $
									}()
									var fetchContainersForSortIDsError: NSError?
									if let unorderedChildContainers = managedObjectContext.executeFetchRequest(request, error: &fetchContainersForSortIDsError) as [Container]? {
										println("unorderedChildContainers: \(unorderedChildContainers)")
										let childContainers = map(sortIDs) { (sortID: Int32) -> Container in
											return filter(unorderedChildContainers) { $0.sortID == sortID }.first!
										}
										folder.childContainers = NSOrderedSet(array: childContainers)
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

extension Folder: ManagedIdentifiable {
	override class func entityName() -> String {
		return "Folder"
	}
	class func sortDescriptors() -> [[NSSortDescriptor]] {
		return [[NSSortDescriptor(key: "newestItemDate", ascending: false)]]
	}
}
