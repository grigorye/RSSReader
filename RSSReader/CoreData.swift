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
		self.id = json["id"] as NSString
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
	func importFromJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		self.id = json["id"] as NSString
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
extension Container: ManagedIdentifiable {
	class func entityName() -> String {
		return "Container"
	}
	func importFromUnreadCountJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		self.id = json["id"] as NSString
		self.unreadCount = (json["count"] as NSNumber).intValue
		let timeIntervalSince1970 = (json["newestItemTimestampUsec"] as NSString).doubleValue * 1e-9
		self.newestItemDate = NSDate(timeIntervalSince1970: timeIntervalSince1970)
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
