//
//  MarkingAsRead.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

public let fakeRootTagSuffix = "state/fake/root"
public let rootTagSuffix = "state/com.google/root"
public let readTagSuffix = "state/com.google/read"
public let favoriteTagSuffix = "state/com.google/starred"

let markedAsReadCategory = {
	x$(Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext)!)
}()
let markedAsFavoriteCategory = {
	x$(Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext)!)
}()

extension Folder {
	public static func predicateForFetchingFolderWithTagSuffix(_ tagSuffix: String) -> NSPredicate {
		typealias E = Folder
		return NSPredicate(format: "\(#keyPath(E.streamID)) ENDSWITH %@", argumentArray: [tagSuffix])
	}
	public static func fetchRequestForFolderWithTagSuffix(_ tagSuffix: String) -> NSFetchRequest<Folder> {
		let fetchRequest = Folder.fetchRequestForEntity() … {
			$0.predicate = self.predicateForFetchingFolderWithTagSuffix(tagSuffix)
			$0.fetchLimit = 1
		}
		return fetchRequest
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
		let x = nil != self.categoryForTagSuffix(tagSuffix)
		return x
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
	final func set(included: Bool, in category: Folder) {
		if included {
			categories.insert(category)
			categoriesToBeExcluded.remove(category)
			categoriesToBeIncluded.insert(category)
		}
		else {
			categories.remove(category)
			categoriesToBeExcluded.insert(category)
			categoriesToBeIncluded.remove(category)
		}
		self.pendingUpdateDate = Date()
	}
	@objc dynamic var markedAsFavorite: Bool {
		get {
			return categories.contains(markedAsFavoriteCategory)
		}
		set {
			self.set(included: newValue, in: markedAsFavoriteCategory)
		}
	}
	@objc var markedAsRead: Bool {
		get {
			return categories.contains(markedAsReadCategory)
		}
		set {
			let oldValue = self.markedAsRead
			if (newValue && oldValue) || (!newValue && !oldValue) {
			}
			else {
				let unreadCountDelta = (newValue ? -1 : 1) as Int32
				self.subscription.unreadCount += unreadCountDelta
				for category in self.categories {
					category.unreadCount += unreadCountDelta
				}
				self.set(included: newValue, in: markedAsReadCategory)
			}
		}
	}
}

extension Item {
	public class func allPendingForUpdate(in context: NSManagedObjectContext) throws -> [Item] {
		let fetchRequest = _Self.fetchRequestForEntity() … {
			$0.predicate = NSPredicate(format: "\(#keyPath(pendingUpdateDate)) != nil")
		}
		let items = try context.fetch(fetchRequest)
		return items
	}
}

extension Folder {
	public class func allWithItems(toBeExcluded excluded: Bool, in context: NSManagedObjectContext) throws -> [Folder] {
		let fetchRequest = _Self.fetchRequestForEntity() … {
#if false
			$0.shouldRefreshRefetchedObjects = true
#endif
			let itemsRelationshipName = excluded ? #keyPath(itemsToBeExcluded) : #keyPath(itemsToBeIncluded)
			$0.predicate = NSPredicate(format: "0 < \(itemsRelationshipName).@count")
		}
		let categories = try context.fetch(fetchRequest)
		for category in categories {
#if true
			context.refresh(category, mergeChanges: true)
#endif
			assert(category.items(toBeExcluded: excluded).count > 0)
		}
		return categories
	}
}
