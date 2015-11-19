//
//  MarkingAsRead.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData
import Foundation

public let rootTagSuffix = "state/com.google/root"
public let readTagSuffix = "state/com.google/read"
public let favoriteTagSuffix = "state/com.google/starred"
public let canonicalReadTag = "user/-/state/com.google/read"
public let canonicalFavoriteTag = "user/-/state/com.google/starred"

var markedAsReadCategory: Folder! = {
	return Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext)
}()
var markedAsFavoriteCategory: Folder! = {
	return Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext)
}()

extension Folder {
	public static func predicateForFetchingFolderWithTagSuffix(tagSuffix: String) -> NSPredicate {
		let E = Folder.self
		return NSPredicate(format: "\(E••{$0.streamID}) ENDSWITH %@", argumentArray: [tagSuffix])
	}
	public static func fetchRequestForFolderWithTagSuffix(tagSuffix: String) -> NSFetchRequest {
		let $ = NSFetchRequest(entityName: Folder.entityName())
		$.predicate = self.predicateForFetchingFolderWithTagSuffix(tagSuffix)
		$.fetchLimit = 1
		return $
	}
	public static func folderWithTagSuffix(tagSuffix: String, managedObjectContext: NSManagedObjectContext) -> Folder? {
		let fetchRequest = self.fetchRequestForFolderWithTagSuffix(tagSuffix)
		let folder = (try! managedObjectContext.executeFetchRequest(fetchRequest)).first as! Folder?
		return folder
	}
}

public extension Item {
	func categoryForTagSuffix(tagSuffix: String) -> Folder? {
		let matchingCategories = self.categories.filter { folder in folder.streamID.hasSuffix(tagSuffix) }
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
	dynamic var markedAsFavorite: Bool {
		get {
			return categories.contains(markedAsFavoriteCategory)
		}
		set {
			if newValue {
				mutableCategories.addObject(markedAsFavoriteCategory)
			}
			else {
				mutableCategories.removeObject(markedAsFavoriteCategory)
			}
		}
	}
	public var markedAsRead: Bool {
		get {
			return categories.contains(markedAsReadCategory)
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
				if newValue {
					mutableCategories.addObject(markedAsReadCategory)
				}
				else {
					mutableCategories.removeObject(markedAsReadCategory)
				}
			}
		}
	}
}
