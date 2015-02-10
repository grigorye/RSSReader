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
	// MARK: - State Preservation and Restoration
	private enum Restorable: String {
		case pageViewControllers = "pageViewControllers"
	}
	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)
		let dataSource = self.dataSource as! ItemsPageViewControllerDataSource
		dataSource.decodeRestorableStateWithCoder(coder)
		if _1 {
			let viewControllers = coder.decodeObjectForKey(Restorable.pageViewControllers.rawValue) as! [UIViewController]
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
			coder.encodeObject(self.viewControllers, forKey: Restorable.pageViewControllers.rawValue)
		}
	}
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		for i in blocksDelayedTillViewWillAppear { i() }
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
	}
}

