//
//  ContainerViewState.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

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

	@NSManaged public var lastLoadedItemDate: Date?
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
	static private let initializeOnce: Ignored = {
#if false
		cachePropertyWithName(_Self.self, name: #keyPath(lastLoadedItem))
#endif
		return Ignored()
	}()
	public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		_ = ContainerViewState.initializeOnce
		super.init(entity: entity, insertInto: context)
	}
}
