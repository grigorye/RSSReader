//
//  ItemsPageViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

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
			self.currentViewController = viewControllers[currentViewControllerIndex]
			blocksDelayedTillViewWillAppear += [{
				self.setViewControllers(viewControllers, direction: .Forward, animated: false) { completed in
					$(completed).$()
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
			let currentViewControllerIndex = viewControllers!.indexOf(self.currentViewController!)
			coder.encodeObject(currentViewControllerIndex, forKey: Restorable.currentViewControllerIndex.rawValue)
		}
	}
	// MARK: -
	override func setViewControllers(viewControllers: [UIViewController]?, direction: UIPageViewControllerNavigationDirection, animated: Bool, completion: ((Bool) -> Void)?) {
		let currentViewController = viewControllers!.first
		super.setViewControllers(viewControllers, direction: direction, animated: animated, completion: completion)
		self.currentViewController = currentViewController
	}
	// MARK: -
	@IBAction func swipe(sender: UIPanGestureRecognizer!) {
		$(self).$()
		let webView = self.currentViewController?.view.subviews.first as? UIWebView
		if sender.velocityInView(webView).y > 0 {
			self.navigationController!.setNavigationBarHidden(false, animated: true)
			self.navigationController!.setToolbarHidden(false, animated: true)
		}
		else {
			self.navigationController!.setToolbarHidden(true, animated: true)
		}
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	override func viewWillAppear(animated: Bool) {
		for i in blocksDelayedTillViewWillAppear { i() }
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
		viewDidDisappearRetainedObjects += [KVOBinding(self•{$0.currentViewController!.navigationItem.rightBarButtonItems}, options: .Initial) { change in
			self.navigationItem.rightBarButtonItems = self.currentViewController!.navigationItem.rightBarButtonItems
		}]
		if hideBarsOnSwipe {
			viewDidDisappearRetainedObjects += [KVOBinding(self•{$0.currentViewController}, options: .Initial) { change in
				if let webView = self.currentViewController?.view.subviews.first as? UIWebView {
					let barHideOnSwipeGestureRecognizer = self.navigationController!.barHideOnSwipeGestureRecognizer
					if (nil == webView.gestureRecognizers) || (nil == webView.gestureRecognizers!.indexOf(barHideOnSwipeGestureRecognizer)) {
						webView.addGestureRecognizer(barHideOnSwipeGestureRecognizer)
						let scrollView = webView.scrollView
						let gestureRecognizer = scrollView.gestureRecognizers!.filter { $0 is UIPanGestureRecognizer }.first!
						gestureRecognizer.addTarget(self, action: "swipe:")
					}
				}
			}]
		}
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if let webView = self.currentViewController?.view.subviews.first as? UIWebView {
			webView.scrollView.flashScrollIndicators()
		}
	}
	override func viewDidDisappear(animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
}

