//
//  RSSSessionTaskResultImporting.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GECoreData
import typealias GEFoundation.Json
import CoreData
import Foundation

extension TypedUserDefaults {
	@NSManaged var batchSavingEnabled: Bool
}
private var batchSavingEnabled: Bool {
	return defaults.batchSavingEnabled
}

func itemsImportedFromStreamJson(_ json: Json, loadDate: Date, container: Container, excludedCategory: Folder?, managedObjectContext: NSManagedObjectContext) throws -> (existing: [Item], new: [Item]) {
	let subscription = container as? Subscription
	let itemJsons = json["items"] as! [Json]
	let categoryIDs = Array(try itemJsons.reduce(Set<String>()) {
		guard let categoryIDs = $1["categories"] as? [String] else {
			throw Item.ItemError.categoriesMissingOrInvalidInJson(json: json)
		}
		return $0.union(categoryIDs)
	})
	let (existingCategories, newCategories): ([Folder], [Folder]) = try insertedObjectsUnlessFetchedWithID(Folder.self, ids: Array(categoryIDs), managedObjectContext: managedObjectContext)
	let categories = existingCategories + newCategories
	let categoriesByID: [String : Folder] = categories.reduce([:]) {
		var acc = $0; acc[$1.streamID] = $1; return acc
	}
	let (existingItems, newItems, removedItems) = try importItemsFromJson(json, type: Item.self, elementName: "items", managedObjectContext: managedObjectContext) { (item, itemJson) in
		try item.importFromJson(itemJson, subscription: subscription, categoriesByID: categoriesByID)
		if !batchSavingEnabled {
			try managedObjectContext.save()
		}
	}
	if let excludedCategory = excludedCategory, 0 < existingItems.count {
		let fetchRequest = Item.fetchRequestForEntity() … {
			typealias E = Item
			$0.predicate = NSPredicate(
				format: "self in %@ && SUBQUERY(\(#keyPath(E.categoryItems.category)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count != 0",
				argumentArray: [
					existingItems.map { $0.objectID },
					excludedCategory.streamID
				]
			)
		}
		let existingItemsNowAssignedToExcludedCategory = try! managedObjectContext.fetch(fetchRequest)
		for item in existingItemsNowAssignedToExcludedCategory {
			item.categories.subtract([excludedCategory])
		}
	}
	if !batchSavingEnabled {
		assert(!managedObjectContext.hasChanges)
	}
	_ = x$(removedItems.count)
	return (existing: existingItems, new: newItems)
}

func continuationAndItemsImportedFromStreamData(_ data: Data, loadDate: Date, container: Container, excludedCategory: Folder?, managedObjectContext: NSManagedObjectContext) throws -> (continuation: String?, (existing: [Item], new: [Item])) {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? Json else {
		throw RSSSessionError.jsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	let continuation = json["continuation"] as? String
	let items = try itemsImportedFromStreamJson(json, loadDate: loadDate, container: container, excludedCategory: excludedCategory, managedObjectContext: managedObjectContext)
	return (continuation, items)
}

func containersImportedFromUnreadCountsData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws -> [Container] {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? Json else {
		throw RSSSessionError.jsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	guard let itemJsons = json["unreadcounts"] as? [Json] else {
		throw RSSSessionError.jsonMissingUnreadCounts(json: json)
	}
	let containers = try itemJsons.map { (itemJson: Json) -> Container in
		guard let itemID = itemJson["id"] as? String else {
			throw RSSSessionError.itemJsonMissingID(itemJson: itemJson)
		}
		let container: Container = try {
			if itemID.hasPrefix("feed/http") {
				let type = Subscription.self
				return try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext)
			}
			else {
				let type = Folder.self
				return try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext)
			}
		}()
		container.importFromUnreadCountJson(itemJson)
		return container
	}
	return (containers)
}

func readFolderImportedFromUserInfoData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws -> Folder {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? Json else {
		throw RSSSessionError.jsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	guard let userID = json["userId"] as? String else {
		throw RSSSessionError.jsonMissingUserID(json: json)
	}
	let id = "user/\(userID)/\(readTagSuffix)"
	return try insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: managedObjectContext)
}

func tagsImportedFromJsonData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws -> (existing: [Folder], new: [Folder], removed: [Folder]) {
	let tags = try importItemsFromJsonData(data, type: Folder.self, elementName: "tags", managedObjectContext: (managedObjectContext)) { (tag, json) in
		assert(tag.managedObjectContext == managedObjectContext)
		if _1 {
			try tag.importFromJson(json)
		}
	}
	return tags
}

func streamPreferencesImportedFromJsonData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? Json else {
		throw RSSSessionError.jsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	guard let streamprefsJson: AnyObject = json["streamprefs"] else {
		throw RSSSessionError.jsonMissingStreamPrefs(json: json)
	}
	try Container.importStreamPreferencesJson(streamprefsJson, managedObjectContext: managedObjectContext)
}

func importedSubscriptionsFromJsonData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws -> (existing: [Subscription], new: [Subscription], removed: [Subscription]) {
	let subscriptions = try importItemsFromJsonData(data, type: Subscription.self, elementName: "subscriptions", managedObjectContext: managedObjectContext) { (subscription, json) in
		try subscription.importFromJson(json)
	}
	return subscriptions
}

func authTokenImportedFromJsonData(_ data: Data) throws -> String {
	let body = String(data: data, encoding: String.Encoding.utf8)!
	let authLocationIndex = body.range(of: "Auth=")!.upperBound
	let authTail = body[authLocationIndex...]
	let lastIndexInAuthTail = authTail.range(of: "\n")!.lowerBound
	let authToken = authTail[..<lastIndexInAuthTail]
	return String(authToken)
}
