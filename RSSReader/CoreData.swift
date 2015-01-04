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
		self.streamID = (json["origin"] as? NSDictionary)?["streamId"] as NSString
	}
}
extension Subscription : ManagedIdentifiable {
	class func entityName() -> String {
		return "Subscription"
	}
	func importFromJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		self.id = json["id"] as NSString
		self.title = json["title"] as NSString?
		self.url = NSURL(string: json["url"] as NSString)
		self.iconURL = NSURL(string: json["iconUrl"] as NSString)
		self.htmlURL = NSURL(string: json["htmlUrl"] as NSString)
	}
}
extension Folder: ManagedIdentifiable {
	class func entityName() -> String {
		return "Folder"
	}
	func importFromJson(jsonObject: AnyObject) {
		let json = jsonObject as [String: AnyObject]
		self.id = json["id"] as NSString
		self.unreadCount = (json["count"] as NSNumber).intValue
		let timeIntervalSince1970 = (json["newestItemTimestampUsec"] as NSString).doubleValue * 1e-9
		self.newestItemDate = NSDate(timeIntervalSince1970: timeIntervalSince1970)
	}
}
