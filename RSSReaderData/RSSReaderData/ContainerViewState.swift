//
//  ContainerViewState.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData.NSManagedObject

public let sortDescriptorsForContainers = [SortDescriptor(key: #keyPath(Item.date), ascending: false)]
public let inversedSortDescriptorsForContainers = inversedSortDescriptors(sortDescriptorsForContainers)

func inversedSortDescriptors(_ sortDescriptors: [SortDescriptor]) -> [SortDescriptor] {
	return sortDescriptors.map {
		return SortDescriptor(key: $0.key, ascending: !$0.ascending)
	}
}

public class ContainerViewState: NSManagedObject {
	typealias _Self = ContainerViewState
	enum ValidationError: ErrorProtocol {
		case NeitherLoadDateNorErrorIsSet
	}
	@NSManaged public var containerViewPredicate: Predicate
    @NSManaged public var continuation: String?
    public var loadError: ErrorProtocol?
    @NSManaged public var loadDate: Date?
    @NSManaged public var loadCompleted: Bool
    @NSManaged public var container: Container?

	@objc dynamic public var lastLoadedItem: Item? {
		guard let loadDate = self.loadDate else {
			return nil
		}
		let fetchRequest: NSFetchRequest<Item> = {
			let $ = Item.fetchRequestForEntity()
			$.predicate = Predicate(format: "\(#keyPath(Item.loadDate)) == %@", argumentArray: [loadDate])
			$.fetchLimit = 1
			$.sortDescriptors = inversedSortDescriptorsForContainers
			return $
		}()
		let item = try! self.managedObjectContext!.fetch(fetchRequest).onlyElement
		return (item)
	}
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
	static private var registerCachedPropertiesOnce = {
		cachePropertyWithName(_Self.self, name: #keyPath(lastLoadedItem))
	}
	override public class func initialize() {
		super.initialize()
		_ = registerCachedPropertiesOnce
	}
}
