//
//  CoreDataGlobals.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import class GECoreData.PersistentContainerWithCustomDirectory
import CoreData

extension TypedUserDefaults {

	@NSManaged var coreDataCachingEnabled: Bool
	@NSManaged var backgroundImportEnabled: Bool
	@NSManaged var forceStoreRemoval: Bool
	@NSManaged var savingDisabled: Bool
	@NSManaged var persistentContainerEnabled: Bool
	@NSManaged var multipleBackgroundContextsEnabled: Bool
}

public class RSSData {
	
	private static let persistentStoreName = "RSSReader"
	
	static let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: NSClassFromString("RSSReaderData.Folder")!)])!

	private static func regeneratedPSC() throws -> NSPersistentStoreCoordinator {
		let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let fileManager = FileManager.default
		
		let persistentStoreDirectoryURL: URL = {
			let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
			return urls[0]
		}()
		if !(try persistentStoreDirectoryURL.checkResourceIsReachable()) {
			try fileManager.createDirectory(at: persistentStoreDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		}
		let storeURL = persistentStoreDirectoryURL.appendingPathComponent("\(persistentStoreName).sqlite")
		x$(fileManager.fileExists(atPath: x$(storeURL.path)))
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

	private enum ManagedObjectContextOrError {
		case error(Error)
		case managedObjectContext(NSManagedObjectContext)
	}
	private let saveQueueManagedObjectContextOrError: ManagedObjectContextOrError = {
		do {
			let saveQueueManagedObjectContext = try NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType) … {
				$0.name = "save"
				$0.persistentStoreCoordinator = try regeneratedPSC()
			}
			return .managedObjectContext(saveQueueManagedObjectContext)
		}
		catch {
			return .error(error)
		}
	}()
	var saveQueueManagedObjectContext: NSManagedObjectContext? {
		guard case .managedObjectContext(let managedObjectContext) = saveQueueManagedObjectContextOrError else {
			return nil
		}
		return managedObjectContext
	}
	var managedObjectContextError: Error? {
		guard case .error(let error) = saveQueueManagedObjectContextOrError else {
			return nil
		}
		return error
	}

	lazy private (set) var persistentMainQueueManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)…{
		$0.name = "main"
		$0.parent = saveQueueManagedObjectContext
	}

	func newBoundMainQueueManagedObjectContext() -> NSManagedObjectContext {
		guard #available(iOS 10.0, *), defaults.persistentContainerEnabled else {
			return persistentMainQueueManagedObjectContext
		}
		assert(0 < persistentContainer.persistentStoreCoordinator.persistentStores.count)
		return persistentContainer.viewContext
	}

	private var mainQueueMOCAutosaver: ManagedObjectContextAutosaver?

	private (set) lazy var mainQueueManagedObjectContext: NSManagedObjectContext = newBoundMainQueueManagedObjectContext() … {
		
		if !defaults.savingDisabled {
			mainQueueMOCAutosaver = ManagedObjectContextAutosaver(managedObjectContext: $0, queue: nil)
		}
	}

	func newBackgroundQueueManagedObjectContext() -> NSManagedObjectContext {

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
	}

	private (set) lazy var backgroundQueueManagedObjectContext: NSManagedObjectContext = newBackgroundQueueManagedObjectContext() … {
		
		if !defaults.savingDisabled {
			saveQueueMOCAutosaver = ManagedObjectContextAutosaver(managedObjectContext: $0, queue: nil)
		}
	}

	func performBackgroundMOCTask(_ task: @escaping (NSManagedObjectContext) -> Void) {
		guard #available(iOS 10.0, *), defaults.persistentContainerEnabled, defaults.multipleBackgroundContextsEnabled else {
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			return backgroundQueueManagedObjectContext.perform {
				task(backgroundQueueManagedObjectContext)
			}
		}
		return persistentContainer.performBackgroundTask { context in
			context.name = "background"
			task(context)
		}
	}

	let persistentContainer = PersistentContainerWithCustomDirectory(name: persistentStoreName, managedObjectModel: managedObjectModel)

	func loadPersistentStores(completionHandler: @escaping (Error?) -> ()) {
		guard #available(iOS 10.0, *), defaults.persistentContainerEnabled else {
			completionHandler(managedObjectContextError)
			return
		}
		persistentContainer.loadPersistentStoresAndWait { [weak persistentContainer] error in
			guard let persistentContainer = persistentContainer else {
				return
			}
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

	func erasePersistentStores() throws {
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
}

extension NSPersistentContainer {
	
	struct LoadPersistentStoresError : Error {
		let errorsAndDescriptions: [(Error, NSPersistentStoreDescription)]
	}
	
	private func configureViewContext(_ viewContext: NSManagedObjectContext) {
		viewContext … {
			$0.name = "view"
			$0.automaticallyMergesChangesFromParent = true
		}
	}
	
	func completeLoadPersistentStoresAndWait(_ completionHandler: @escaping (Error?) -> Void) {
		configureViewContext(viewContext)
		completionHandler(nil)
	}
	
	func loadPersistentStoresAndWait(completionHandler: @escaping (Error?) -> Void) {
		if defaults.forceStoreRemoval {
			for storeDescription in persistentStoreDescriptions {
				x$(storeDescription.url)
			}
		}
		var descriptionsToComplete = persistentStoreDescriptions.count
		var errorsAndDescriptions = [(Error, NSPersistentStoreDescription)]()
		let completionQueue = DispatchQueue(label: "loadPersistentStoresCompletion")
		loadPersistentStores { (description, error) in
			x$(description)
			completionQueue.async { [weak self] in
				guard let pself = self else {
					return
				}
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
				pself.completeLoadPersistentStoresAndWait(completionHandler)
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
	
	func removeAllObjects() throws {
		guard let persistentStoreCoordinator = persistentStoreCoordinator else {
			return
		}
		try removeAllObjects(for: persistentStoreCoordinator.managedObjectModel.entities)
	}
}

var rssDataImp: RSSData? = nil

var rssData: RSSData {
	guard let rssDataImp = rssDataImp else {
		let rssDataImp = RSSData()
		RSSReaderData.rssDataImp = rssDataImp
		return rssDataImp
	}
	return rssDataImp
}

public var mainQueueManagedObjectContext: NSManagedObjectContext {
	
	return rssData.mainQueueManagedObjectContext
}

public func performBackgroundMOCTask(_ task: @escaping (NSManagedObjectContext) -> Void) {
	
	rssData.performBackgroundMOCTask(task)
}

public func loadPersistentStores(completionHandler: @escaping (Error?) -> ()) {
	
	rssData.loadPersistentStores(completionHandler: completionHandler)
}

public func erasePersistentStores() throws {
	
	try rssData.erasePersistentStores()
}
