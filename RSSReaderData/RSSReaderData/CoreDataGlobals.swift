//
//  CoreDataGlobals.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

extension TypedUserDefaults {

	@NSManaged var coreDataCachingEnabled: Bool
	@NSManaged var backgroundImportEnabled: Bool
	@NSManaged var forceStoreRemoval: Bool
	@NSManaged var savingDisabled: Bool
	@NSManaged var persistentContainerEnabled: Bool
	@NSManaged var multipleBackgroundContextsEnabled: Bool

}

let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: NSClassFromString("RSSReaderData.Folder")!)])!

private func regeneratedPSC() throws -> NSPersistentStoreCoordinator {
	let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
	let fileManager = FileManager.default
	let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
	let documentsDirectoryURL = urls[0]
	if !fileManager.fileExists(atPath: documentsDirectoryURL.path) {
		try fileManager.createDirectory(at: documentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
	}
	let storeURL = documentsDirectoryURL.appendingPathComponent("RSSReaderData.sqlite")
	x$(fileManager.fileExists(atPath: storeURL.path))
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
private let (managedObjectContextError, saveQueueManagedObjectContext): (Error?, NSManagedObjectContext?) = {
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
let persistentMainQueueManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)…{
	$0.name = "main"
	$0.parent = saveQueueManagedObjectContext
	if !defaults.savingDisabled {
		mainQueueMOCAutosaver = ManagedObjectContextAutosaver(managedObjectContext: $0, queue: nil)
	}
}

public var mainQueueManagedObjectContext: NSManagedObjectContext {
	guard #available(iOS 10.0, *), defaults.persistentContainerEnabled else {
		return persistentMainQueueManagedObjectContext
	}
	return persistentContainer.viewContext
}

let backgroundQueueManagedObjectContext: NSManagedObjectContext = {
	guard defaults.backgroundImportEnabled else {
		return mainQueueManagedObjectContext
	}
	guard #available(iOS 10.0, *), defaults.persistentContainerEnabled else {
		return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType) … {
			$0.name = "background"
			$0.parent = mainQueueManagedObjectContext
			if defaults.coreDataCachingEnabled {
				$0.cachingEnabled = true
			}
		}
	}
	return persistentContainer.newBackgroundContext() … {
		$0.name = "background"
	}
}()

public func performBackgroundMOCTask(_ task: @escaping (NSManagedObjectContext) -> Void) {
	guard #available(iOS 10.0, *), defaults.persistentContainerEnabled, defaults.multipleBackgroundContextsEnabled else {
		return backgroundQueueManagedObjectContext.perform {
			task(backgroundQueueManagedObjectContext)
		}
	}
	return persistentContainer.performBackgroundTask { context in
		context.name = "background"
		task(context)
	}
}

@available (iOS 10.0, *)
let persistentContainer = NSPersistentContainer(name: "RSSReader", managedObjectModel: managedObjectModel) … {
	$0.viewContext … {
		$0.name = "view"
		$0.automaticallyMergesChangesFromParent = true
	}
	()
}

@available (iOS 10.0, *)
struct LoadPersistentStoresError : Error {
	let errorsAndDescriptions: [(Error, NSPersistentStoreDescription)]
}

@available (iOS 10.0, *)
extension NSPersistentContainer {

	func loadPersistentStoresAndWait(completionHandler: @escaping (Error?) -> Void) {
		if defaults.forceStoreRemoval {
			for storeDescription in persistentContainer.persistentStoreDescriptions {
				x$(storeDescription.url)
			}
		}
		var descriptionsToComplete = persistentContainer.persistentStoreDescriptions.count
		var errorsAndDescriptions = [(Error, NSPersistentStoreDescription)]()
		let completionQueue = DispatchQueue(label: "loadPersistentStoresCompletion")
		loadPersistentStores { (description, error) in
			x$(description)
			completionQueue.async {
				if let error = error {
					errorsAndDescriptions += [(error, description)]
				}
				descriptionsToComplete -= 1
				guard 0 == descriptionsToComplete else {
					return
				}
				guard 0 == errorsAndDescriptions.count else {
					completionHandler(LoadPersistentStoresError(errorsAndDescriptions: errorsAndDescriptions))
					return
				}
				completionHandler(nil)
			}
		}
	}
	
}

extension NSManagedObjectContext {

	func removeAllObjects(for entities: [NSEntityDescription]) throws {
		for entity in entities {
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>() … {
				$0.entity = entity
				$0.includesSubentities = false
			}
			let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
			try execute(deleteRequest)
		}
	}
	
}

public func loadPersistentStores(completionHandler: @escaping (Error?) -> ()) {
	guard #available(iOS 10.0, *), defaults.persistentContainerEnabled else {
		completionHandler(managedObjectContextError)
		return
	}
	persistentContainer.loadPersistentStoresAndWait { error in
		guard nil == error else {
			completionHandler(error!)
			return
		}
		guard !defaults.forceStoreRemoval else {
			let context = persistentContainer.viewContext
			context.perform {
				try! context.removeAllObjects(for: persistentContainer.managedObjectModel.entities)
				try! context.save()
				completionHandler(nil)
			}
			return
		}
		completionHandler(nil)
	}
}

public func erasePersistentStores() throws {
	guard #available(iOS 10.0, *), defaults.persistentContainerEnabled else {
		assert(false)
		return
	}
	for storeDescription in persistentContainer.persistentStoreDescriptions {
		let fileManager = FileManager()
		// ".RSSReader.sqlite.migrationdestination_41b5a6b5c6e848c462a8480cd24caef3"
		// ".RSSReader.sqlite.migrationdestination_41b5a6b5c6e848c462a8480cd24caef3-shm"
		// ".RSSReader.sqlite.migrationdestination_41b5a6b5c6e848c462a8480cd24caef3-wal"
		// "RSSReader.sqlite"
		// "RSSReader.sqlite-shm"
		// "RSSReader.sqlite-wal"
		let storeBasenameURL = storeDescription.url!.deletingPathExtension()
		for pathExtension in ["sqlite", "sqlite-shm", "sqlite-wal"] {
			let storeFileURL = storeBasenameURL.appendingPathExtension(pathExtension)
			try fileManager.removeItem(at: storeFileURL)
		}
	}
}
