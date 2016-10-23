//
//  ItemPageViewControllerDataSource.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEFoundation
import GEBase
import UIKit

class ItemPageViewControllerDataSource: NSObject, UIPageViewControllerDataSource {
	var items: [Item]!
	func viewControllerForItem(_ item: Item, storyboard: UIStoryboard) -> UIViewController {
		return (storyboard.instantiateViewController(withIdentifier: MainStoryboard.StoryboardIdentifiers.ItemSummaryWeb) as! ItemSummaryWebViewController) … {
			$0.item = item
		}
	}
	// MARK: -
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as! ItemSummaryWebViewController
		let item = itemViewController.item!
		let itemBefore: Item? = {
			let items = self.items!
			if items.first == item {
				return nil
			}
			else {
				let index = items.index(of: item)!
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
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as! ItemSummaryWebViewController
		let item = itemViewController.item!
		let itemAfter: Item? = {
			let items = self.items!
			if items.last == item {
				return nil
			}
			else {
				let index = items.index(of: item)!
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
	func encodeRestorableStateWithCoder(_ coder: NSCoder) {
		let itemObjectIDURLs = self.items.map { $0.objectID.uriRepresentation() }
		coder.encode(itemObjectIDURLs, forKey: Restorable.itemObjectIDURLs.rawValue)
	}
	func decodeRestorableStateWithCoder(_ coder: NSCoder) {
		let managedObjectContext = mainQueueManagedObjectContext
		let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator!
		let itemObjectIDURLs = coder.decodeObject(forKey: Restorable.itemObjectIDURLs.rawValue) as! [URL]
		let items = itemObjectIDURLs.map { managedObjectContext.object(with: persistentStoreCoordinator.managedObjectID(forURIRepresentation: $0)!) as! Item }
		self.items = items
	}
	// MARK: -
	deinit {
	}
}
