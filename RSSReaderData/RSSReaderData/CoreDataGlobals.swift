//
//  CoreDataGlobals.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation
import CoreData

public let (managedObjectContextError, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext, supplementaryObjects): (ErrorType?, NSManagedObjectContext!, NSManagedObjectContext!, [AnyObject]) = {
	do {
		let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(forClass: NSClassFromString("RSSReaderData.Folder")!)])!
		let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let fileManager = NSFileManager.defaultManager()
		let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		let documentsDirectoryURL = urls[0]
		if !fileManager.fileExistsAtPath(documentsDirectoryURL.path!) {
			try fileManager.createDirectoryAtURL(documentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		}
		let storeURL = documentsDirectoryURL.URLByAppendingPathComponent("RSSReaderData.sqlite")
		$(fileManager.fileExistsAtPath(storeURL.path!))
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
			if defaults.coreDataCachingEnabled {
				$.cachingEnabled = true
			}
			return $
		}()
		let backgroundQueueManagedObjectContext: NSManagedObjectContext = {
			guard defaults.backgroundImportEnabled else {
				return mainQueueManagedObjectContext
			}
			let $ = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
			$.parentContext = mainQueueManagedObjectContext
			$.name = "background"
			if defaults.coreDataCachingEnabled {
				$.cachingEnabled = true
			}
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
