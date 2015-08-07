//
//  CoreDataGlobals.swift
//  RSSReader
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

public let (managedObjectContextError, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext, supplementaryObjects): (ErrorType?, NSManagedObjectContext!, NSManagedObjectContext!, [AnyObject]) = {
	do {
		let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(forClass: NSClassFromString("RSSReaderData.Folder")!)])!
		let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		let documentsDirectory = paths[0]
		let fileManager = NSFileManager.defaultManager()
		if !fileManager.fileExistsAtPath(documentsDirectory) {
			try fileManager.createDirectoryAtPath(documentsDirectory, withIntermediateDirectories: true, attributes: nil)
		}
		let storeURL = NSURL.fileURLWithPath((documentsDirectory as NSString).stringByAppendingPathComponent("RSSReader.sqlite"))
		$(fileManager.fileExistsAtPath(storeURL.path!)).$()
		if NSUserDefaults().boolForKey("forceStoreRemoval") {
			let fileManager = NSFileManager.defaultManager()
			do {
				try fileManager.removeItemAtURL(storeURL)
			}
			catch NSCocoaError.FileNoSuchFileError {
			}
		}
		do {
			let options = [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true
			]
			let persistentStore = try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
		} catch let error as NSCocoaError {
			switch error.rawValue {
			case NSMigrationMissingSourceModelError where NSUserDefaults().boolForKey("allowMissingSourceModelError"):
			fallthrough
			case NSPersistentStoreIncompatibleVersionHashError, NSMigrationError:
				let fileManager = NSFileManager.defaultManager()
				try fileManager.removeItemAtURL(storeURL)
				try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
			default:
				throw error
			}
		}
		let mainQueueManagedObjectContext: NSManagedObjectContext = {
			let $ = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
			$.persistentStoreCoordinator = psc
			$.name = "main"
			return $
		}()
		let backgroundQueueManagedObjectContext: NSManagedObjectContext = {
			let $ = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
			$.parentContext = mainQueueManagedObjectContext
			$.name = "background"
			return $
		}()
		var supplementaryObjects = [AnyObject]()
		supplementaryObjects += [
			ManagedObjectContextAutosaver(managedObjectContext: mainQueueManagedObjectContext, queue: nil)
		]
		return (nil, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext, supplementaryObjects)
	}
	catch {
		return (error, nil, nil, [])
	}
}()
