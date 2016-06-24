//
//  GenericCoreDataExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

enum GenericCoreDataExtensionsError: ErrorProtocol {
	case JsonObjectIsNotDictionary(jsonObject: AnyObject)
	case ElementNotFoundOrInvalidInJson(json: [String: AnyObject], elementName: String)
}

public protocol Managed {
	static func entityName() -> String
}

public protocol DefaultSortable {
	static func defaultSortDescriptor() -> SortDescriptor
}

public protocol Identifiable {
	static func identifierKey() -> String
}

public protocol ManagedIdentifiable: Managed, Identifiable {
}

func objectFetchedWithPredicate<T: Managed where T: NSManagedObject, T: NSFetchRequestResult> (_ cls: T.Type, predicate: Predicate, managedObjectContext: NSManagedObjectContext) -> T? {
	let entityName = cls.entityName()
	let request: NSFetchRequest<T>
	do {
		let $ = NSFetchRequest<T>(entityName: entityName)
		$.predicate = predicate
		$.fetchLimit = 1
		request = $
	}
	let objects = try! managedObjectContext.fetch(request)
	let object = objects.last
	if let object = object {
		void(managedObjectContext.object(with: object.objectID))
		assert(object.managedObjectContext == managedObjectContext)
	}
	return object
}

func insertedObjectUnlessFetchedWithPredicate<T: Managed where T: NSManagedObject, T: NSFetchRequestResult>(_ cls: T.Type, predicate: Predicate, managedObjectContext: NSManagedObjectContext, newObjectInitializationHandler: (T) -> Void) throws -> T {
	let entityName = cls.entityName()
	if let existingObject = objectFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) {
		return existingObject
	}
	else {
		let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! T
		newObjectInitializationHandler(newObject)
		return newObject
	}
}
public func insertedObjectUnlessFetchedWithID<T: NSManagedObject where T: ManagedIdentifiable, T: NSFetchRequestResult>(_ cls: T.Type, id: String, managedObjectContext: NSManagedObjectContext) throws -> T {
	let identifierKey = cls.identifierKey()
	let predicate = Predicate(format: "%K == %@", argumentArray: [identifierKey, id])
	return try insertedObjectUnlessFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext) { newObject in
		(newObject as NSManagedObject).setValue(id, forKey:identifierKey)
	}
}
public func importItemsFromJson<T: ManagedIdentifiable where T: NSManagedObject, T: NSFetchRequestResult>(_ json: [String : AnyObject], type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] {
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
public func importItemsFromJsonData<T: ManagedIdentifiable where T: NSManagedObject, T: NSFetchRequestResult>(_ data: Data, type: T.Type, elementName: String, managedObjectContext: NSManagedObjectContext, importFromJson: (T, [String: AnyObject]) throws -> Void) throws -> [T] {
	let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
	guard let json = jsonObject as? [String : AnyObject] else {
		throw GenericCoreDataExtensionsError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
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
	public func sameObject<T: NSManagedObject>(as object: T) -> T {
		return self.object(with: object.objectID) as! T
	}
}

#if os(iOS)
public func stringFromFetchedResultsChangeType(_ type: NSFetchedResultsChangeType) -> String {
	switch (type) {
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
