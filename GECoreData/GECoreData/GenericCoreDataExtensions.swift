//
//  GenericCoreDataExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

enum GenericCoreDataExtensionsError: Error {
	case jsonObjectIsNotDictionary(jsonObject: Any)
	case elementNotFoundOrInvalidInJson(json: [String: AnyObject], elementName: String)
}

public protocol Managed : NSFetchRequestResult {
}

public extension Managed where Self : NSManagedObject {
    static func fetchRequestForEntity() -> NSFetchRequest<Self> {
        return self.fetchRequest() as! NSFetchRequest<Self>
    }
}

public protocol DefaultSortable {
	static func defaultSortDescriptor() -> NSSortDescriptor
}

public protocol Identifiable {
	static func identifierKey() -> String
}

public protocol ManagedIdentifiable: Managed, Identifiable {
}

func objectFetchedWithPredicate<T: Managed> (_ cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext) -> T? where T: NSManagedObject {
	let request = T.fetchRequestForEntity() … {
		$0.predicate = predicate
		$0.fetchLimit = 1
	}
	let objects = try! managedObjectContext.fetch(request)
	let object = objects.last
	if let object = object {
		•(managedObjectContext.object(with: object.objectID))
		assert(object.managedObjectContext == managedObjectContext)
	}
	return object
}

func objectsFetchedWithPredicate<T: Managed> (_ cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext) -> [T] where T: NSManagedObject {
	let request: NSFetchRequest<T> = T.fetchRequestForEntity() … {
		$0.predicate = predicate
	}
	let objects = try! managedObjectContext.fetch(request)
	return objects
}

func insertedObjectUnlessFetchedWithPredicate<T: Managed>(_ cls: T.Type, predicate: NSPredicate, managedObjectContext: NSManagedObjectContext, newObjectInitializationHandler: (T) -> Void) throws -> T where T: NSManagedObject {
	let entityName = cls.entity().name!
	if let existingObject = objectFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) {
		return existingObject
	}
	else {
		let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! T
		newObjectInitializationHandler(newObject)
		return newObject
	}
}
public func insertedObjectUnlessFetchedWithID<T: NSManagedObject>(_ cls: T.Type, id: String, managedObjectContext: NSManagedObjectContext) throws -> T where T: ManagedIdentifiable {
	let identifierKey = cls.identifierKey()
	let predicate = NSPredicate(format: "%K == %@", argumentArray: [identifierKey, id])
	return try insertedObjectUnlessFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) { newObject in
		(newObject as NSManagedObject).setValue(id, forKey:identifierKey)
	}
}

public func insertedObjectsUnlessFetchedWithID<T: NSManagedObject>(_ cls: T.Type, ids: [String], managedObjectContext: NSManagedObjectContext) throws -> (existing: [T], new: [T]) where T: ManagedIdentifiable {
	let identifierKey = cls.identifierKey()
	let predicate = NSPredicate(format: "%K in %@", argumentArray: [identifierKey, ids])
	let existingObjects = objectsFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext)
	let existingIDs = existingObjects.map { $0.value(forKey: identifierKey)! as! String }
	let newIDs = ids.filter { !existingIDs.contains($0) }
	let entityName = cls.entity().name!
	let newObjects: [T] = newIDs.map {
		let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! T
		(newObject as NSManagedObject).setValue($0, forKey:identifierKey)
		return newObject
	}
	return (existing: existingObjects, new: newObjects)
}

public func importItemsFromJson<T: ManagedIdentifiable>(_ json: [String : AnyObject], type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> (existing: [T], new: [T]) where T: NSManagedObject {
	guard let itemJsons = json[elementName] as? [Json] else {
		throw GenericCoreDataExtensionsError.elementNotFoundOrInvalidInJson(json: json, elementName: elementName)
	}
	let itemJsonsByIDs: [String : Json] = try itemJsons.map { (itemJson: Json) -> (String, Json) in
		guard let itemID = itemJson["id"] as? String else {
			throw GenericCoreDataExtensionsError.elementNotFoundOrInvalidInJson(json: json, elementName: "id")
		}
		return (itemID, itemJson)
	}.reduce([String : Json]()) { var acc = $0; acc[$1.0] = $1.1; return acc }
	let itemIDs: [String] = Array(itemJsonsByIDs.keys)
	let (existingItems, newItems) = try insertedObjectsUnlessFetchedWithID(type, ids: itemIDs, managedObjectContext: managedObjectContext)
	let itemIDKey = type.identifierKey() as String
	for item in newItems + existingItems {
		let itemJson = itemJsonsByIDs[item.value(forKey: itemIDKey) as! String]!
		try importFromJson(item, itemJson)
	}
	return (existing: existingItems, new: newItems)
}

public func importItemsFromJsonData<T: ManagedIdentifiable>(_ data: Data, type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> (existing: [T], new: [T]) where T: NSManagedObject {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? [String : AnyObject] else {
		throw GenericCoreDataExtensionsError.jsonObjectIsNotDictionary(jsonObject: jsonObject)
	}
	let items = try importItemsFromJson(json, type: type, elementName: elementName, managedObjectContext: managedObjectContext, importFromJson: importFromJson)
	return items
}

extension NSManagedObject {
	public func encodeObjectIDWithCoder(_ coder: NSCoder, key: String) {
		coder.encode(objectID.uriRepresentation(), forKey: key)
	}
}
extension NSManagedObjectContext {
	public class func objectWithIDDecodedWithCoder(_ coder: NSCoder, key: String, managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
		if let objectIDURL = coder.decodeObject(forKey: key) as! URL? {
            if let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: objectIDURL) {
                return managedObjectContext.object(with: objectID)
            }
			else {
				x$(objectIDURL)
			}
        }
        else {
			x$(key)
		}
		return nil
	}
}

public struct TypedManagedObjectID<T> {
	let objectID: NSManagedObjectID
	public func object(in managedObjectContext: NSManagedObjectContext) -> T {
		return managedObjectContext.object(with: objectID) as! T
	}
}

public func typedObjectID<T: NSManagedObject>(for object: T) -> TypedManagedObjectID<T> {
	return TypedManagedObjectID(objectID: object.objectID)
}
public func typedObjectID<T: NSManagedObject>(for object: T?) -> TypedManagedObjectID<T>? {
	guard let object = object else {
		return nil
	}
	return TypedManagedObjectID(objectID: object.objectID)
}

#if os(iOS)
public func stringFromFetchedResultsChangeType(_ type: NSFetchedResultsChangeType) -> String {
	switch type {
	case .insert:
		return "Insert"
	case .delete:
		return "Delete"
	case .update:
		return "Update"
	case .move:
		return "Move"
	}
}
#endif
