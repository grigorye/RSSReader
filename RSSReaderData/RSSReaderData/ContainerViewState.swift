//
//  ContainerViewState.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import GEBase
import CoreData.NSManagedObject

public let sortDescriptorsForContainers = [NSSortDescriptor(key: Item.self••{$0.date}, ascending: false)]
public let inversedSortDescriptorsForContainers = inversedSortDescriptors(sortDescriptorsForContainers)

func inversedSortDescriptors(sortDescriptors: [NSSortDescriptor]) -> [NSSortDescriptor] {
	return sortDescriptors.map {
		return NSSortDescriptor(key: $0.key, ascending: !$0.ascending)
	}
}

public class ContainerViewState: NSManagedObject {
	typealias _Self = ContainerViewState
	enum ValidationError: ErrorType {
		case NeitherLoadDateNorErrorIsSet
	}
	@NSManaged public var containerViewPredicate: NSPredicate
    @NSManaged public var continuation: String?
    public var loadError: ErrorType?
    @NSManaged public var loadDate: NSDate?
    @NSManaged public var loadCompleted: Bool
    @NSManaged public var container: Container?

	@objc dynamic public var lastLoadedItem: Item? {
		guard let loadDate = self.loadDate else {
			return nil
		}
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: "Item")
			$.predicate = NSPredicate(format: "\(Item.self••{$0.loadDate}) == %@", argumentArray: [loadDate])
			$.fetchLimit = 1
			$.sortDescriptors = inversedSortDescriptorsForContainers
			return $
		}()
		let item = try! self.managedObjectContext!.executeFetchRequest(fetchRequest).onlyElement as! Item?
		return $(item)
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
	private static var registerCachedPropertiesOnce = dispatch_once_t()
	override public class func initialize() {
		super.initialize()
		dispatch_once(&registerCachedPropertiesOnce) {
			cachePropertyWithName(self, name: "lastLoadedItem")
		}
	}
}
