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

protocol ManagedIdentifiable {
	var id: String { get }
	class func entityName() -> String
	func importFromJson(jsonObject: AnyObject)
}

func importJson<T: ManagedIdentifiable>(cls: T.Type, json: [String: AnyObject], #managedObjectContext: NSManagedObjectContext, error: NSErrorPointer) -> T? {
	let id = json["id"] as NSString
	let entityName = cls.entityName()
	let (existingObject: T?, errorForExistingObject: NSError?) = {
		let request: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: entityName)
			$.predicate = NSPredicate(format: "id == %@", argumentArray: [id])
			$.fetchLimit = 1
			return $
		}()
		var fetchError: NSError?
		let objects = managedObjectContext.executeFetchRequest(request, error: &fetchError)
		if nil == objects {
			return (nil, trace("fetchError", fetchError))
		}
		let existingObject = objects?.last as T?
		return (existingObject, nil)
	}()
	if let errorForExistingObject = errorForExistingObject {
		error.memory = errorForExistingObject
		return nil
	}
	let object: T = existingObject ?? {
		let newObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as T
		return newObject
	}()
	object.importFromJson(json)
	return object
}
func importItemsFromJson<T: ManagedIdentifiable>(json: [String : AnyObject], #type: T.Type, #elementName: NSString, #managedObjectContext: NSManagedObjectContext, #error: NSErrorPointer) -> [T]? {
	var items = [T]()
	let completionError: NSError? = {
		let itemJsons = json[elementName] as? [[String : AnyObject]]
		if nil == itemJsons {
			let jsonElementNotFoundOrInvalidError = NSError(domain: GenericCoreDataExtensionsErrorDomain, code: GenericCoreDataExtensionsError.JsonElementNotFoundOrInvalid.rawValue, userInfo: nil)
			return trace("jsonElementNotFoundOrInvalidError", jsonElementNotFoundOrInvalidError)
		}
		for itemJson in itemJsons! {
			var importItemError: NSError?
			let item = importJson(type, itemJson, managedObjectContext: managedObjectContext, &importItemError)
			if nil == item {
				return trace("importItemError", importItemError)
			}
			items += [item!]
		}
		return nil
	}()
	if let completionError = completionError {
		error.memory = trace("completionError", completionError)
		return nil
	}
	return items
}
func importItemsFromJsonData<T: ManagedIdentifiable>(data: NSData, #type: T.Type, #elementName: NSString, #managedObjectContext: NSManagedObjectContext, #error: NSErrorPointer) -> [T]? {
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
	return importItemsFromJson(json!, type: type, elementName: elementName, managedObjectContext: managedObjectContext, error: error)
}
