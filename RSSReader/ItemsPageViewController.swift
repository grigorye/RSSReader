//
//  ItemsPageViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit.UIPageViewController

class ItemsPageViewController : UIPageViewController {
	var blocksDelayedTillViewWillAppear = [Handler]()
	dynamic var currentViewController: UIViewController?
	// MARK: - State Preservation and Restoration
	private enum Restorable: String {
		case viewControllers = "viewControllers"
		case currentViewControllerIndex = "currentViewControllerIndex"
	}
	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)
		let dataSource = self.dataSource as! ItemsPageViewControllerDataSource
		dataSource.decodeRestorableStateWithCoder(coder)
		if _1 {
			let viewControllers = coder.decodeObjectForKey(Restorable.viewControllers.rawValue) as! [UIViewController]
			let currentViewControllerIndex = coder.decodeObjectForKey(Restorable.currentViewControllerIndex.rawValue) as! Int
			let delegate = self.delegate as! ItemsPageViewControllerDelegate
			self.currentViewController = viewControllers[0]
			blocksDelayedTillViewWillAppear += [{
				self.setViewControllers(viewControllers, direction: .Forward, animated: false) { completed in
					void(trace("completed", completed))
				}
			}]
		}
	}
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		let dataSource = self.dataSource as! ItemsPageViewControllerDataSource
		dataSource.encodeRestorableStateWithCoder(coder)
		if _1 {
			coder.encodeObject(viewControllers, forKey: Restorable.viewControllers.rawValue)
			let currentViewControllerIndex = find(viewControllers as! [UIViewController], self.currentViewController!)
			coder.encodeObject(currentViewControllerIndex, forKey: Restorable.currentViewControllerIndex.rawValue)
		}
	}
	override func setViewControllers(viewControllers: [AnyObject]!, direction: UIPageViewControllerNavigationDirection, animated: Bool, completion: ((Bool) -> Void)!) {
		self.currentViewController = Optional(viewControllers[0] as! UIViewController)
		super.setViewControllers(viewControllers, direction: direction, animated: animated, completion: completion)
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	override func viewWillAppear(animated: Bool) {
		for i in blocksDelayedTillViewWillAppear { i() }
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
		viewDidDisappearRetainedObjects += [KVOBinding(object: self, keyPath: "currentViewController.navigationItem.rightBarButtonItems", options: .Initial) { change in
			self.navigationItem.rightBarButtonItems = self.currentViewController!.navigationItem.rightBarButtonItems
		}]
	}
	override func viewDidDisappear(animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
}

