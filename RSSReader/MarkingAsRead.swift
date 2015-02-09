//
//  MarkingAsRead.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

let rootTagSuffix = "state/com.google/root"
let readTagSuffix = "state/com.google/read"
let favoriteTagSuffix = "state/com.google/starred"
let canonicalReadTag = "user/-/state/com.google/read"
let canonicalFavoriteTag = "user/-/state/com.google/starred"

extension Folder {
	class func predicateForFetchingFolderWithTagSuffix(tagSuffix: String) -> NSPredicate {
		return NSPredicate(format: "id ENDSWITH %@", argumentArray: [tagSuffix])
	}
	class func fetchRequestForFolderWithTagSuffix(tagSuffix: String) -> NSFetchRequest {
		let $ = NSFetchRequest(entityName: Folder.entityName())
		$.predicate = self.predicateForFetchingFolderWithTagSuffix(tagSuffix)
		$.fetchLimit = 1
		return $
	}
	class func folderWithTagSuffix(tagSuffix: String, managedObjectContext: NSManagedObjectContext) -> Folder? {
		let fetchRequest = self.fetchRequestForFolderWithTagSuffix(tagSuffix)
		var executeFetchRequestError: NSError?
		let folder = managedObjectContext.executeFetchRequest(fetchRequest, error: &executeFetchRequestError)?.first as! Folder?
		return folder
	}
}

extension Item {
	func categoryForTagSuffix(tagSuffix: String) -> Folder? {
		let matchingCategories = filter(self.categories) { folder in folder.id.hasSuffix(tagSuffix) }
		return matchingCategories.first
	}
	func includedInCategoryWithTagSuffix(tagSuffix: String) -> Bool {
		let $ = nil != self.categoryForTagSuffix(tagSuffix)
		return $
	}
	func setIncludedInCategoryWithTagSuffix(tagSuffix: String, newValue: Bool) {
		let oldValue = includedInCategoryWithTagSuffix(tagSuffix)
		if (newValue && oldValue) || (!newValue && !oldValue) {
		}
		else {
			let mutableCategories = self.mutableCategories
			if newValue {
				let folder = Folder.folderWithTagSuffix(tagSuffix, managedObjectContext: self.managedObjectContext!)!
				mutableCategories.addObject(folder)
			}
			else {
				mutableCategories.removeObject(self.categoryForTagSuffix(tagSuffix)!)
			}
		}
	}
	// MARK: -
	var markedAsFavorite: Bool {
		get {
			return includedInCategoryWithTagSuffix(favoriteTagSuffix)
		}
		set {
			setIncludedInCategoryWithTagSuffix(favoriteTagSuffix, newValue: newValue)
		}
	}
	var markedAsRead: Bool {
		get {
			return includedInCategoryWithTagSuffix(readTagSuffix)
		}
		set {
			let oldValue = self.markedAsRead
			if ((newValue && oldValue) || (!newValue && !oldValue)) {
			}
			else {
				let unreadCountDelta = newValue ? -1 : 1
				self.subscription.unreadCount += unreadCountDelta
				for category in self.categories {
					category.unreadCount += unreadCountDelta
				}
				setIncludedInCategoryWithTagSuffix(readTagSuffix, newValue: newValue)
			}
		}
	}
}
