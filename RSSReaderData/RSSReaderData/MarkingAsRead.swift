//
//  MarkingAsRead.swift
//  RSSReaderData
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

let markedAsReadCategory = Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext)!
let markedAsFavoriteCategory = Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext)!

extension Folder {
	public static func predicateForFetchingFolderWithTagSuffix(_ tagSuffix: String) -> Predicate {
		typealias E = Folder
		return Predicate(format: "\(#keyPath(E.streamID)) ENDSWITH %@", argumentArray: [tagSuffix])
	}
	public static func fetchRequestForFolderWithTagSuffix(_ tagSuffix: String) -> NSFetchRequest<Folder> {
		let $ = Folder.fetchRequestForEntity()
		$.predicate = self.predicateForFetchingFolderWithTagSuffix(tagSuffix)
		$.fetchLimit = 1
		return $
	}
	public static func folderWithTagSuffix(_ tagSuffix: String, managedObjectContext: NSManagedObjectContext) -> Folder? {
		let fetchRequest = self.fetchRequestForFolderWithTagSuffix(tagSuffix)
		let folder = (try! managedObjectContext.fetch(fetchRequest)).onlyElement
		return folder
	}
}

public extension Item {
	func categoryForTagSuffix(_ tagSuffix: String) -> Folder? {
		let matchingCategories = self.categories.filter { folder in folder.streamID.hasSuffix(tagSuffix) }
		return matchingCategories.onlyElement
	}
	func includedInCategoryWithTagSuffix(_ tagSuffix: String) -> Bool {
		let $ = nil != self.categoryForTagSuffix(tagSuffix)
		return $
	}
	func setIncludedInCategoryWithTagSuffix(_ tagSuffix: String, newValue: Bool) {
		let oldValue = includedInCategoryWithTagSuffix(tagSuffix)
		if (newValue && oldValue) || (!newValue && !oldValue) {
		}
		else {
			if newValue {
				let folder = Folder.folderWithTagSuffix(tagSuffix, managedObjectContext: self.managedObjectContext!)!
				self.categories.insert(folder)
			}
			else {
				self.categories.remove(self.categoryForTagSuffix(tagSuffix)!)
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
				self.categories.insert(markedAsFavoriteCategory)
			}
			else {
				self.categories.remove(markedAsFavoriteCategory)
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
					self.categories.insert(markedAsReadCategory)
				}
				else {
					self.categories.remove(markedAsReadCategory)
				}
			}
		}
	}
}
