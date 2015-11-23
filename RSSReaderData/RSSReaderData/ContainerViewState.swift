//
//  ContainerViewState.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 16/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import CoreData.NSManagedObject

public let sortDescriptorsForContainers = [NSSortDescriptor(key: Item.self••{$0.date}, ascending: false)]
public let inversedSortDescriptorsForContainers = inversedSortDescriptors(sortDescriptorsForContainers)

func inversedSortDescriptors(sortDescriptors: [NSSortDescriptor]) -> [NSSortDescriptor] {
	return sortDescriptors.map {
		return NSSortDescriptor(key: $0.key, ascending: !$0.ascending)
	}
}

public class ContainerViewState: NSManagedObject {
	@NSManaged public var containerViewPredicate: NSPredicate
    @NSManaged public var continuation: String?
    public var loadError: ErrorType?
    @NSManaged public var loadDate: NSDate
    @NSManaged public var loadCompleted: Bool
    @NSManaged public var container: Container?

	public var lastLoadedItem: Item? {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: "Item")
			$.predicate = NSPredicate(format: "\(Item.self••{$0.loadDate}) == %@", argumentArray: [self.loadDate])
			$.fetchLimit = 1
			$.sortDescriptors = inversedSortDescriptorsForContainers
			return $
		}()
		let item = try! self.managedObjectContext!.executeFetchRequest(fetchRequest).first as! Item?
		return item
	}
	deinit {
	}
}
