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

public let (managedObjectContextError, optionalMainQueueManagedObjectContext, optionalBackgroundQueueManagedObjectContext, supplementaryObjects): (ErrorProtocol?, NSManagedObjectContext?, NSManagedObjectContext?, [AnyObject]) = {
	do {
		let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: NSClassFromString("RSSReaderData.Folder")!)])!
		let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let fileManager = FileManager.default()
		let urls = fileManager.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)
		let documentsDirectoryURL = urls[0]
		if !fileManager.fileExists(atPath: documentsDirectoryURL.path!) {
			try fileManager.createDirectory(at: documentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		}
		let storeURL = try documentsDirectoryURL.appendingPathComponent("RSSReaderData.sqlite")
		$(fileManager.fileExists(atPath: storeURL.path!))
		if UserDefaults().bool(forKey: "forceStoreRemoval") {
			let fileManager = FileManager.default()
			do {
				try fileManager.removeItem(at: storeURL)
			}
			catch NSCocoaError.fileNoSuchFileError {
			}
		}
		do {
			let options = [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true
			]
			let persistentStore = try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
		} catch let error as NSCocoaError {
			switch error.rawValue {
			case NSMigrationMissingSourceModelError where UserDefaults().bool(forKey: "allowMissingSourceModelError"):
			fallthrough
			case NSPersistentStoreIncompatibleVersionHashError, NSMigrationError:
				let fileManager = FileManager.default()
				try fileManager.removeItem(at: storeURL)
				try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
			default:
				throw error
			}
		}
		let mainQueueManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) … {
			$0.persistentStoreCoordinator = psc
			$0.name = "main"
			if defaults.coreDataCachingEnabled {
				$0.cachingEnabled = true
			}
		}
		let backgroundQueueManagedObjectContext: NSManagedObjectContext = {
			guard defaults.backgroundImportEnabled else {
				return mainQueueManagedObjectContext
			}
			return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType) … {
				$0.parent = mainQueueManagedObjectContext
				$0.name = "background"
				if defaults.coreDataCachingEnabled {
					$0.cachingEnabled = true
				}
			}
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

public let mainQueueManagedObjectContext = { optionalMainQueueManagedObjectContext! }()
public let backgroundQueueManagedObjectContext = { optionalBackgroundQueueManagedObjectContext! }()
