//
//  GenericCoreDataExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

let GenericCoreDataExtensionsErrorDomain = "com.grigoryentin.GenericCoreDataExtensions"

enum GenericCoreDataExtensionsError: Int {
	case JsonElementNotFoundOrInvalid
}

protocol Managed {
	static func entityName() -> String
}

protocol DefaultSortable {
	static func defaultSortDescriptor() -> NSSortDescriptor
}

protocol ManagedIdentifiable : Managed {
	static func identifierKey() -> String
}

func insertedObjectUnlessFetchedWithPredicate<T: ManagedIdentifiable>(cls: T.Type, #predicate: NSPredicate, #managedObjectContext: NSManagedObjectContext, #error: NSErrorPointer, newObjectInitializationHandler: (T) -> Void) -> T? {
	let entityName = cls.entityName()
	let (existingObject: T?, errorForExistingObject: NSError?) = {
		let request: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: entityName)
			$.predicate = predicate
			$.fetchLimit = 1
			return $
		}()
		var fetchError: NSError?
		let objects = managedObjectContext.executeFetchRequest(request, error: &fetchError)
		if nil == objects {
			return (nil, trace("fetchError", fetchError))
		}
		let existingObject = objects?.last as! T?
		return (existingObject, nil)
	}()
	if let errorForExistingObject = errorForExistingObject {
		error.memory = errorForExistingObject
		return nil
	}
	let object: T = nil != existingObject ? existingObject! : {
		let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! T
		newObjectInitializationHandler(newObject)
		return newObject
	}()
	return object
}
func insertedObjectUnlessFetchedWithID<T: ManagedIdentifiable where T : NSManagedObject>(cls: T.Type, #id: String, #managedObjectContext: NSManagedObjectContext, #error: NSErrorPointer) -> T? {
	let identifierKey = cls.identifierKey()
	let predicate = NSPredicate(format: "%K == %@", argumentArray: [identifierKey, id])
	return insertedObjectUnlessFetchedWithPredicate(cls, predicate: predicate, managedObjectContext: managedObjectContext, error: error) { newObject in
		newObject.setValue(id, forKey:identifierKey)
	}
}
func importItemsFromJson<T: ManagedIdentifiable where T : NSManagedObject>(json: [String : AnyObject], #type: T.Type, #elementName: NSString, #managedObjectContext: NSManagedObjectContext, #error: NSErrorPointer, #importFromJson: (T, [String: AnyObject], NSErrorPointer) -> Bool) -> [T]? {
	var items = [T]()
	let completionError: NSError? = {
		let itemJsons = json[elementName as! String] as? [[String : AnyObject]]
		if nil == itemJsons {
			let jsonElementNotFoundOrInvalidError = NSError(domain: GenericCoreDataExtensionsErrorDomain, code: GenericCoreDataExtensionsError.JsonElementNotFoundOrInvalid.rawValue, userInfo: nil)
			return trace("jsonElementNotFoundOrInvalidError", jsonElementNotFoundOrInvalidError)
		}
		for itemJson in itemJsons! {
			var insertOrFetchItemError: NSError?
			let itemID = itemJson["id"] as! String
			if let item = insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext, error: &insertOrFetchItemError) {
				var itemImportError: NSError?
				if !importFromJson(item, itemJson, &itemImportError) {
					return trace("itemImportError", itemImportError)
				}
				items += [item]
			}
			else {
				return trace("insertOrFetchItemError", insertOrFetchItemError)
			}
		}
		return nil
	}()
	if let completionError = completionError {
		error.memory = trace("completionError", completionError)
		return nil
	}
	return items
}
func importItemsFromJsonData<T: ManagedIdentifiable where T : NSManagedObject>(data: NSData, #type: T.Type, #elementName: NSString, #managedObjectContext: NSManagedObjectContext, #error: NSErrorPointer, #importFromJson: (T, [String: AnyObject], NSErrorPointer) -> Bool) -> [T]? {
	let (json: [String : AnyObject]?, jsonError: NSError?) = {
		var jsonParseError: NSError?
		let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &jsonParseError)
		if nil == jsonObject {
			return (nil, trace("jsonParseError", jsonParseError))
		}
		let json = jsonObject as? [String : AnyObject]
		if nil == json {
			let jsonIsNotDictionaryError = NSError()
			return (json, trace("jsonIsNotDictionaryError", jsonIsNotDictionaryError))
		}
		return (json, nil)
	}()
	if let jsonError = jsonError {
		error.memory = trace("jsonError", jsonError)
		return nil
	}
	return importItemsFromJson(json!, type: type, elementName: elementName, managedObjectContext: managedObjectContext, error: error, importFromJson: importFromJson)
}

extension NSManagedObject {
	func encodeObjectIDWithCoder(coder: NSCoder, key: String) {
		coder.encodeObject(objectID.URIRepresentation(), forKey: key)
	}
}
extension NSManagedObjectContext {
	class func objectWithIDDecodedWithCoder(coder: NSCoder, key: String, managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
		if let objectIDURL = coder.decodeObjectForKey(key) as! NSURL? {
            if let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIDURL) {
                return managedObjectContext.objectWithID(objectID)
            }
			else {
				void(trace("objectIDURLMissingObject", objectIDURL));
			}
        }
        else {
			void(trace("keyMissingObjectIDURL", key));
		}
		return nil
	}
}