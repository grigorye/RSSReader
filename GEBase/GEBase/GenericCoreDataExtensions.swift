//
//  GenericCoreDataExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

enum GenericCoreDataExtensionsError: ErrorType {
	case JsonObjectIsNotDictionary(jsonObject: AnyObject)
	case ElementNotFoundOrInvalidInJson(json: [String: AnyObject], elementName: String)
}

public protocol Managed {
	static func entityName() -> String
}

public protocol DefaultSortable {
	static func defaultSortDescriptor() -> NSSortDescriptor
}

public protocol Identifiable {
	static func identifierKey() -> String
}

public protocol ManagedIdentifiable: Managed, Identifiable {
}

func objectFetchedWithPredicate<T: Managed where T: NSManagedObject>(cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext) -> T? {
	let entityName = cls.entityName()
	let request: NSFetchRequest = {
		let $ = NSFetchRequest(entityName: entityName)
		$.predicate = predicate
		$.fetchLimit = 1
		return $
	}()
	let objects = try! (managedObjectContext).executeFetchRequest((request))
	let object = objects.last as! T?
	if let object = object {
		void(managedObjectContext.objectWithID(object.objectID))
	}
	assert((nil == object) || (object?.managedObjectContext == managedObjectContext))
	return object
}

func insertedObjectUnlessFetchedWithPredicate<T: Managed where T: NSManagedObject>(cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext, newObjectInitializationHandler: (T) -> Void) throws -> T {
	let entityName = cls.entityName()
	if let existingObject = objectFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) {
		return existingObject
	}
	else {
		let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! T
		newObjectInitializationHandler(newObject)
		return newObject
	}
}
public func insertedObjectUnlessFetchedWithID<T: ManagedIdentifiable where T: NSManagedObject>(cls: T.Type, id: String, managedObjectContext: NSManagedObjectContext) throws -> T {
	let identifierKey = cls.identifierKey()
	let predicate = NSPredicate(format: "%K == %@", argumentArray: [identifierKey, id])
	return try insertedObjectUnlessFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) { newObject in
		(newObject as NSManagedObject).setValue(id, forKey:identifierKey)
	}
}
public func importItemsFromJson<T: ManagedIdentifiable where T: NSManagedObject>(json: [String : AnyObject], type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] {
	var items = [T]()
	guard let itemJsons = json[elementName] as? [[String : AnyObject]] else {
		throw GenericCoreDataExtensionsError.ElementNotFoundOrInvalidInJson(json: json, elementName: elementName)
	}
	for itemJson in itemJsons {
		guard let itemID = itemJson["id"] as? String else {
			throw GenericCoreDataExtensionsError.ElementNotFoundOrInvalidInJson(json: json, elementName: "id")
		}
		let item = try insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext)
		try importFromJson(item, itemJson)
		items += [item]
	}
	return items
}
public func importItemsFromJsonData<T: ManagedIdentifiable where T: NSManagedObject>(data: NSData, type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] {
	let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
	guard let json = jsonObject as? [String : AnyObject] else {
		throw GenericCoreDataExtensionsError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	let items = try importItemsFromJson(json, type: type, elementName: elementName, managedObjectContext: managedObjectContext, importFromJson: importFromJson)
	return items
}

extension NSManagedObject {
	public func encodeObjectIDWithCoder(coder: NSCoder, key: String) {
		coder.encodeObject(objectID.URIRepresentation(), forKey: key)
	}
}
extension NSManagedObjectContext {
	public class func objectWithIDDecodedWithCoder(coder: NSCoder, key: String, managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
		if let objectIDURL = coder.decodeObjectForKey(key) as! NSURL? {
            if let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIDURL) {
                return managedObjectContext.objectWithID(objectID)
            }
			else {
				$(objectIDURL)
			}
        }
        else {
			$(key)
		}
		return nil
	}
}
extension NSManagedObjectContext {
	public func sameObject<T: NSManagedObject>(object: T) -> T {
		return self.objectWithID(object.objectID) as! T
	}
}

#if os(iOS)
public func stringFromFetchedResultsChangeType(type: NSFetchedResultsChangeType) -> String {
	switch (type) {
	case .Insert:
		return "Insert"
	case .Delete:
		return "Delete"
	case .Update:
		return "Update"
	case .Move:
		return "Move"
	}
}
#endif
