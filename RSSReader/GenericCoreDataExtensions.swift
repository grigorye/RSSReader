//
//  GenericCoreDataExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

protocol ManagedIdentifiable {
	var id: String { get }
	class func entityName() -> String
	func importFromJson(jsonObject: AnyObject)
}

func importJson<T: ManagedIdentifiable>(cls: T.Type, json: NSDictionary, #managedObjectContext: NSManagedObjectContext) -> NSError? {
	let id = json["id"] as NSString
	var existingObject: T?
	let entityName = cls.entityName()
	let errorForExistingObject: NSError? = {
		let request: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: entityName)
			$.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
			$.fetchLimit = 1
			return $
		}()
		var fetchError: NSError?
		if let objects = managedObjectContext.executeFetchRequest(request, error: &fetchError) {
			if objects.count > 0 {
				existingObject = (objects[0] as T)
			}
			else {
				existingObject = nil
			}
			return nil
		}
		else {
			return fetchError
		}
	}()
	if let errorForExistingObject = errorForExistingObject {
		return errorForExistingObject
	}
	let object: T = existingObject ?? {
		let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as T
		return newObject
	}()
	object.importFromJson(json)
	return nil
}
