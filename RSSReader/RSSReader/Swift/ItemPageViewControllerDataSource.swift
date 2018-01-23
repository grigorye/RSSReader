//
//  ItemPageViewControllerDataSource.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import CoreData
import UIKit

class ItemPageViewControllerDataSource: NSObject, UIPageViewControllerDataSource {
	var itemsController: NSFetchedResultsController<Item>!
	func viewControllerForItem(_ item: Item) -> UIViewController {
		return R.storyboard.main.itemSummaryWeb()! … {
			$0.item = item
		}
	}
	// MARK: -
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as! ItemSummaryWebViewController
		let item = itemViewController.item!
		let itemBefore = object(in: itemsController, indexedBy: -1, from: item)
		if let itemBefore = itemBefore {
			return viewControllerForItem(itemBefore)
		}
		else {
			return nil
		}
	}
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as! ItemSummaryWebViewController
		let item = itemViewController.item!
		let itemAfter = object(in: itemsController, indexedBy: +1, from: item)
		if let itemAfter = itemAfter {
			return viewControllerForItem(itemAfter)
		}
		else {
			return nil
		}
	}
	// MARK: - State Preservation and Restoration
	private enum Restorable : String {
		case itemObjectIDURLs
	}
	func encodeRestorableStateWithCoder(_ coder: NSCoder) {
		#if false
		let itemObjectIDURLs = self.items.map { $0.objectID.uriRepresentation() }
		coder.encode(itemObjectIDURLs, forKey: Restorable.itemObjectIDURLs.rawValue)
		#endif
	}
	func decodeRestorableStateWithCoder(_ coder: NSCoder) {
		#if false
		let managedObjectContext = mainQueueManagedObjectContext
		let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator!
		let itemObjectIDURLs = coder.decodeObject(forKey: Restorable.itemObjectIDURLs.rawValue) as! [URL]
		let items = itemObjectIDURLs.map { managedObjectContext.object(with: persistentStoreCoordinator.managedObjectID(forURIRepresentation: $0)!) as! Item }
		self.items = items
		#endif
	}
	// MARK: -
	deinit {
	}
}
