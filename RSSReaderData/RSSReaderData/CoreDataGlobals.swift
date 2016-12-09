//
//  CoreDataGlobals.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

extension KVOCompliantUserDefaults {
	@NSManaged var coreDataCachingEnabled: Bool
	@NSManaged var backgroundImportEnabled: Bool
	@NSManaged var forceStoreRemoval: Bool
	@NSManaged var savingDisabled: Bool
}

private func regeneratedPSC() throws -> NSPersistentStoreCoordinator {
	let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: NSClassFromString("RSSReaderData.Folder")!)])!
	let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
	let fileManager = FileManager.default
	let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
	let documentsDirectoryURL = urls[0]
	if !fileManager.fileExists(atPath: documentsDirectoryURL.path) {
		try fileManager.createDirectory(at: documentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
	}
	let storeURL = documentsDirectoryURL.appendingPathComponent("RSSReaderData.sqlite")
	$(fileManager.fileExists(atPath: storeURL.path))
	if defaults.forceStoreRemoval {
		let fileManager = FileManager.default
		do {
			try fileManager.removeItem(at: storeURL)
		}
		catch CocoaError.fileNoSuchFile {
		}
	}
	do {
		let options = [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption: true
		]
		_ = try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
	} catch let error as CocoaError {
		switch error.code.rawValue {
		case NSMigrationMissingSourceModelError where UserDefaults().bool(forKey: "allowMissingSourceModelError"):
		fallthrough
		case NSPersistentStoreIncompatibleVersionHashError, NSMigrationError:
			let fileManager = FileManager.default
			try fileManager.removeItem(at: storeURL)
			try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
		default:
			throw error
		}
	}
	return psc
}

private var saveQueueMOCAutosaver: ManagedObjectContextAutosaver?
public let (managedObjectContextError, saveQueueManagedObjectContext): (Error?, NSManagedObjectContext?) = {
	do {
		let saveQueueManagedObjectContext = try NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType) … {
			$0.name = "save"
			$0.persistentStoreCoordinator = try regeneratedPSC()
		}
		if !defaults.savingDisabled {
			saveQueueMOCAutosaver = ManagedObjectContextAutosaver(managedObjectContext: saveQueueManagedObjectContext, queue: nil)
		}
		return (nil, saveQueueManagedObjectContext)
	}
	catch {
		return (error, nil)
	}
}()

private var mainQueueMOCAutosaver: ManagedObjectContextAutosaver?
public let mainQueueManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)…{
	$0.name = "main"
	$0.parent = saveQueueManagedObjectContext
	if !defaults.savingDisabled {
		mainQueueMOCAutosaver = ManagedObjectContextAutosaver(managedObjectContext: $0, queue: nil)
	}
}

public let backgroundQueueManagedObjectContext: NSManagedObjectContext = {
	guard defaults.backgroundImportEnabled else {
		return mainQueueManagedObjectContext
	}
	return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType) … {
		$0.name = "background"
		$0.parent = mainQueueManagedObjectContext
		if defaults.coreDataCachingEnabled {
			$0.cachingEnabled = true
		}
	}
}()
