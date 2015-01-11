//
//  ItemsPageViewControllerDataSource.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class ItemsPageViewControllerDataSource: NSObject, UIPageViewControllerDataSource {
	var folder: Container?
	var items: [Item]!
	func viewControllerForItem(item: Item, storyboard: UIStoryboard) -> UIViewController {
		let $ = storyboard.instantiateViewControllerWithIdentifier(ViewControllerStoryboardIdentifier.itemSummaryWeb.rawValue) as ItemSummaryWebViewController
		$.item = item
		return $
	}
	// MARK: -
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let itemViewController = viewController as ItemSummaryWebViewController
		let item = itemViewController.item
		let itemBefore: Item? = {
			let items = self.items
			if items.first == item {
				return nil
			}
			else {
				let index = find(items, item)!
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
		let itemViewController = viewController as ItemSummaryWebViewController
		let item = itemViewController.item
		let itemAfter: Item? = {
			let items = self.items
			if items.last == item {
				return nil
			}
			else {
				let index = find(items, item)!
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
	// MARK: -
	deinit {
	}
}
