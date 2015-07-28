//
//  ItemsPageViewControllerDataSource.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

class ItemsPageViewControllerDataSource: NSObject, UIPageViewControllerDataSource {
	var items: [Item]!
	func viewControllerForItem(item: Item, storyboard: UIStoryboard) -> UIViewController {
		let $ = storyboard.instantiateViewControllerWithIdentifier(MainStoryboard.StoryboardIdentifiers.ItemSummaryWeb) as! ItemSummaryWebViewController
		$.item = item
		return $
	}
	// MARK: -
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as! ItemSummaryWebViewController
		let item = itemViewController.item
		let itemBefore: Item? = {
			let items = self.items
			if items.first == item {
				return nil
			}
			else {
				let index = items.indexOf(item)!
				return items[index - 1]
			}
		}()
		if let itemBefore = itemBefore {
			return viewControllerForItem(itemBefore, storyboard: viewController.storyboard!)
		}
		else {
			return nil
		}
	}
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as! ItemSummaryWebViewController
		let item = itemViewController.item
		let itemAfter: Item? = {
			let items = self.items
			if items.last == item {
				return nil
			}
			else {
				let index = items.indexOf(item)!
				return items[index + 1]
			}
		}()
		if let itemAfter = itemAfter {
			return viewControllerForItem(itemAfter, storyboard: viewController.storyboard!)
		}
		else {
			return nil
		}
	}
	// MARK: - State Preservation and Restoration
	private enum Restorable: String {
		case itemObjectIDURLs = "itemObjectIDURLs"
	}
	func encodeRestorableStateWithCoder(coder: NSCoder) {
		let itemObjectIDURLs = self.items.map { $0.objectID.URIRepresentation() }
		coder.encodeObject(itemObjectIDURLs, forKey: Restorable.itemObjectIDURLs.rawValue)
	}
	func decodeRestorableStateWithCoder(coder: NSCoder) {
		let managedObjectContext = mainQueueManagedObjectContext
		let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator!
		let itemObjectIDURLs = coder.decodeObjectForKey(Restorable.itemObjectIDURLs.rawValue) as! [NSURL]
		let items = itemObjectIDURLs.map { managedObjectContext.objectWithID(persistentStoreCoordinator.managedObjectIDForURIRepresentation($0)!) as! Item }
		self.items = items
	}
	// MARK: -
	deinit {
	}
}
