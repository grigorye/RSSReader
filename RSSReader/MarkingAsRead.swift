//
//  MarkingAsRead.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

let readTagSuffix = "state/com.google/read"
let canonicalReadTag = "user/-/state/com.google/read"

extension Folder {
	class func markedAsReadFolderInContext(managedObjectContext: NSManagedObjectContext) -> Folder {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: Folder.entityName())
			$.predicate = NSPredicate(format: "id ENDSWITH %@", argumentArray: [readTagSuffix])
			$.fetchLimit = 1
			return $
		}()
		var executeFetchRequestError: NSError?
		let folder = managedObjectContext.executeFetchRequest(fetchRequest, error: &executeFetchRequestError)?.first as Folder
		return folder
	}
}

extension Item {
	var categoryForReadTag: Folder? {
		let matchingCategories = filter(self.categories.allObjects as [Folder]) { folder in folder.id.hasSuffix(readTagSuffix) }
		return matchingCategories.first?
	}
	var markedAsRead: Bool {
		get {
			let markedAsRead = nil != self.categoryForReadTag
			return markedAsRead
		}
		set {
			if (newValue && self.markedAsRead) || (!newValue && !self.markedAsRead) {
			}
			else {
				let mutableCategories = self.mutableSetValueForKey("categories")
				if newValue {
					mutableCategories.addObject(Folder.markedAsReadFolderInContext(self.managedObjectContext!))
				}
				else {
					mutableCategories.removeObject(self.categoryForReadTag!)
				}
			}
		}
	}
}