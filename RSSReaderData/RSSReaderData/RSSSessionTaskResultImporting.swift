//
//  RSSSessionTaskResultImporting.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData
import Foundation

private var batchSavingDisabled: Bool {
	return !defaults.batchSavingEnabled
}

func itemsImportedFromStreamJson(_ json: Json, loadDate: Date, container: Container, excludedCategory: Folder?, managedObjectContext: NSManagedObjectContext) throws -> [Item] {
	let subscription = container as? Subscription
	let items = try importItemsFromJson(json, type: Item.self, elementName: "items", managedObjectContext: managedObjectContext) { (item, itemJson) in
		try item.importFromJson(itemJson, subscription: subscription)
		item.loadDate = loadDate
		if batchSavingDisabled {
			try managedObjectContext.save()
		}
	}
	if let excludedCategory = excludedCategory {
		let lastItem = items.last
		let fetchRequest = Item.fetchRequestForEntity() … {
			$0.predicate = Predicate(
				format: "(loadDate != %@) && (date < %@) && (subscription == %@) && SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0",
				argumentArray: [
					loadDate,
					lastItem?.date ?? NSDate.distantFuture(),
					container,
					excludedCategory.streamID
				]
			)
		}
		let itemsNowAssignedToExcludedCategory = try! managedObjectContext.fetch(fetchRequest)
		for item in itemsNowAssignedToExcludedCategory {
			item.categories.formUnion([excludedCategory])
		}
	}
	if !batchSavingDisabled {
		try managedObjectContext.save()
	}
	else {
		assert(!managedObjectContext.hasChanges)
	}
	return items
}

func continuationAndItemsImportedFromStreamData(_ data: Data, loadDate: Date, container: Container, excludedCategory: Folder?, managedObjectContext: NSManagedObjectContext) throws -> (String?, [Item]) {
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
				return try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: backgroundQueueManagedObjectContext)
			}
			else {
				let type = Folder.self
				return try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: backgroundQueueManagedObjectContext)
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

func tagsImportedFromJsonData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws -> [Folder] {
	let tags = try importItemsFromJsonData(data, type: Folder.self, elementName: "tags", managedObjectContext: (backgroundQueueManagedObjectContext)) { (tag, json) in
		assert(tag.managedObjectContext == backgroundQueueManagedObjectContext)
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
	try Container.importStreamPreferencesJson(streamprefsJson, managedObjectContext: backgroundQueueManagedObjectContext)
}

func importedSubscriptionsFromJsonData(_ data: Data, managedObjectContext: NSManagedObjectContext) throws -> [Subscription] {
	let subscriptions = try importItemsFromJsonData(data, type: Subscription.self, elementName: "subscriptions", managedObjectContext: backgroundQueueManagedObjectContext) { (subscription, json) in
		try subscription.importFromJson(json)
	}
	return subscriptions
}

func authTokenImportedFromJsonData(_ data: Data) throws -> String {
	let body = String(data: data, encoding: String.Encoding.utf8)!
	let authLocationIndex = body.range(of: "Auth=")!.upperBound
	let authTail = body.substring(from: authLocationIndex)
	let lastIndexInAuthTail = authTail.range(of: "\n")!.lowerBound
	let authToken = authTail.substring(to: lastIndexInAuthTail)
	return authToken
}
