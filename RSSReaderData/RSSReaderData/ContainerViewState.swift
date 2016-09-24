//
//  ContainerViewState.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData.NSManagedObject

public let sortDescriptorsForContainers = [NSSortDescriptor(key: #keyPath(Item.date), ascending: false)]
public let inversedSortDescriptorsForContainers = inversedSortDescriptors(sortDescriptorsForContainers)

func inversedSortDescriptors(_ sortDescriptors: [NSSortDescriptor]) -> [NSSortDescriptor] {
	return sortDescriptors.map {
		return NSSortDescriptor(key: $0.key, ascending: !$0.ascending)
	}
}

public class ContainerViewState: NSManagedObject {
	typealias _Self = ContainerViewState
	enum ValidationError: Error {
		case NeitherLoadDateNorErrorIsSet
	}
	@NSManaged public var containerViewPredicate: NSPredicate
    @NSManaged public var continuation: String?
    public var loadError: Error?
    @NSManaged public var loadDate: Date?
    @NSManaged public var loadCompleted: Bool
    @NSManaged public var container: Container?

#if false
	@objc dynamic public var lastLoadedItem: Item? {
		guard let loadDate = self.loadDate else {
			return nil
		}
		let fetchRequest = Item.fetchRequestForEntity() … {
			$0.predicate = NSPredicate(format: "\(#keyPath(Item.loadDate)) == %@", argumentArray: [loadDate])
			$0.fetchLimit = 1
			$0.sortDescriptors = inversedSortDescriptorsForContainers
		}
		let item = try! self.managedObjectContext!.fetch(fetchRequest).onlyElement
		return (item)
	}
#else
	@NSManaged public var lastLoadedItem: Item?
#endif
	func validateForUpdateOrInsert() throws {
		if nil == self.loadDate && nil == self.loadError {
			throw ValidationError.NeitherLoadDateNorErrorIsSet
		}
	}
	public override func validateForInsert() throws {
		try super.validateForInsert()
		try self.validateForUpdateOrInsert()
	}
	public override func validateForUpdate() throws {
		try super.validateForUpdate()
		try self.validateForUpdateOrInsert()
	}
	deinit {
	}
	static private let initializeOnce: Void = {
#if false
		cachePropertyWithName(_Self.self, name: #keyPath(lastLoadedItem))
#endif
	}()
	override public class func initialize() {
		super.initialize()
		_ = initializeOnce
	}
}
