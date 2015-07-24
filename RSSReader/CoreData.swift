//
//  CoreData.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

extension NSDate {
	convenience init(timestampUsec: String) {
		let timeIntervalSince1970 = (timestampUsec as NSString).doubleValue * 1e-6
		self.init(timeIntervalSince1970: timeIntervalSince1970)
	}
	var timestampUsec: String {
		get {
			return "\(timeIntervalSince1970 * 1e6)"
		}
	}
	var timestampMsec: String {
		get {
			return "\(timeIntervalSince1970 * 1e3)"
		}
	}
	var timestamp: String {
		get {
			return "\(timeIntervalSince1970)"
		}
	}
}
extension Item : ManagedIdentifiable {
	enum Error: ErrorType {
		case CategoriesMissingOrInvalidInJson(json: [String: AnyObject])
	}
	public class func identifierKey() -> String {
		return "itemID"
	}
	public class func entityName() -> String {
		return "Item"
	}
	func importFromJson(jsonObject: AnyObject) throws {
		let json = jsonObject as! [String: AnyObject]
		let date = NSDate(timestampUsec: json["timestampUsec"] as! String)
		if date == self.date {
			$(self).$(0)
		}
		else {
			self.date = date
			self.title = json["title"] as! String?
			let summary = (json["summary"] as! [String: AnyObject])["content"] as! String?
			self.summary = summary
			let managedObjectContext = self.managedObjectContext!
			let streamID = (json["origin"] as? NSDictionary)?["streamId"] as! String
			let subscription = try insertedObjectUnlessFetchedWithID(Subscription.self, id: streamID, managedObjectContext: managedObjectContext)
			self.subscription = subscription
			self.canonical = json["canonical"] as! [[String : String]]?
			var categories = [Folder]()
			guard let categoriesIDs = json["categories"] as? [String] else {
				throw Error.CategoriesMissingOrInvalidInJson(json: json)
			}
			for categoryID in categoriesIDs {
				let folder = try insertedObjectUnlessFetchedWithID(Folder.self, id: categoryID, managedObjectContext: managedObjectContext)
				categories += [folder]
			}
			let mutableCategories = self.mutableCategories
			mutableCategories.removeAllObjects()
			mutableCategories.addObjectsFromArray(categories)
		}
	}
}

extension Subscription {
	override public class func entityName() -> String {
		return "Subscription"
	}
	class func sortDescriptorsVariants() -> [[NSSortDescriptor]] {
		return [[NSSortDescriptor(key: self••{"sortID"}, ascending: true)]]
	}
	override func importFromJson(jsonObject: AnyObject) throws {
		try super.importFromJson(jsonObject)
		let json = jsonObject as! [String: AnyObject]
		self.title = json["title"] as! String?
		self.url = NSURL(string: json["url"] as! String)
		self.iconURL = NSURL(string: json["iconUrl"] as! String)
		self.htmlURL = NSURL(string: json["htmlUrl"] as! String)
		if let categories = json["categories"] as? [[String: AnyObject]] {
			for category in categories {
				let id = category["id"] as! String
				let folder = try insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: self.managedObjectContext!)
				let mutableCategories = self.mutableSetValueForKey(self••{"categories"})
				mutableCategories.addObject(folder)
			}
		}
	}
}
enum JsonImportError: ErrorType {
	case JsonObjectIsNotDictionary(jsonObject: AnyObject)
	case MissingSortID(json: [String: AnyObject])
	case SortIDIsNotHex(json: [String: AnyObject])
	case SubscriptionOrderingMissingValue(json: [String: AnyObject])
	case MissingPrefsID(json: [String: AnyObject])
	case PrefsMissingValue(prefs: [String: AnyObject])
	case PrefsValueLengthIsNotFactorOf8(prefs: [String: AnyObject])
	case SortIDInPrefsValueIsNotHex(prefs: [String: AnyObject], range: Range<String.Index>)
}

extension Folder {
	override public static func entityName() -> String {
		return "Folder"
	}
	class func sortDescriptors() -> [[NSSortDescriptor]] {
		return [[NSSortDescriptor(key: self••{"newestItemDate"}, ascending: false)]]
	}
}
