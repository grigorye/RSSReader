//
//  ItemPageViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import WebKit.WKWebView
import UIKit

class ItemPageViewController : UIPageViewController {
	@objc dynamic var currentViewController: UIViewController!
	// MARK: - State Preservation and Restoration
	private enum Restorable : String {
		case viewControllers
		case currentViewControllerIndex
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		let dataSource = self.dataSource as! ItemPageViewControllerDataSource
		dataSource.decodeRestorableStateWithCoder(coder)
		if _1 {
			let viewControllers = coder.decodeObject(forKey: Restorable.viewControllers.rawValue) as! [UIViewController]
			let currentViewControllerIndex = coder.decodeObject(forKey: Restorable.currentViewControllerIndex.rawValue) as! Int
			self.currentViewController = viewControllers[currentViewControllerIndex]
			scheduledForViewWillAppear += [{
				self.setViewControllers(viewControllers, direction: .forward, animated: false) { completed in
					x$(completed)
				}
			}]
		}
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		let dataSource = self.dataSource as! ItemPageViewControllerDataSource
		dataSource.encodeRestorableStateWithCoder(coder)
		if _1 {
			coder.encode(viewControllers, forKey: Restorable.viewControllers.rawValue)
			let currentViewControllerIndex = viewControllers!.firstIndex(of: self.currentViewController!)
			coder.encode(currentViewControllerIndex, forKey: Restorable.currentViewControllerIndex.rawValue)
		}
	}
	// MARK: -
	override func setViewControllers(_ viewControllers: [UIViewController]?, direction: UIPageViewController.NavigationDirection, animated: Bool, completion: ((Bool) -> Void)?) {
		let currentViewController = viewControllers!.first
		super.setViewControllers(viewControllers, direction: direction, animated: animated, completion: completion)
		self.currentViewController = currentViewController
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [Any]()
	var scheduledForViewWillAppear = ScheduledHandlers()
	override func viewWillAppear(_ animated: Bool) {
		scheduledForViewWillAppear.perform()
		super.viewWillAppear(animated)
		
		viewDidDisappearRetainedObjects += [self.observe(\.currentViewController.navigationItem.rightBarButtonItems, options: .initial) { (_, _) in
			self.navigationItem.rightBarButtonItems = self.currentViewController!.navigationItem.rightBarButtonItems
		}]
		if hideBarsOnSwipe {
			viewDidDisappearRetainedObjects += [self.observe(\.currentViewController, options: .initial) { (_, _) in
				if let webView = self.currentViewController?.view.subviews.first as? WKWebView {
					let barHideOnSwipeGestureRecognizer = self.navigationController!.barHideOnSwipeGestureRecognizer
					let scrollView = webView.scrollView
					scrollView.addGestureRecognizer(barHideOnSwipeGestureRecognizer)
				}
			}]
		}
		viewDidDisappearRetainedObjects += [self.observe(\.currentViewController.toolbarItems, options: .initial) { (_, _) in
			self.toolbarItems = self.currentViewController?.toolbarItems
		}]
	}
	override var childForStatusBarHidden: UIViewController? {
		return self.currentViewController
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let webView = self.currentViewController?.view.subviews.first as? WKWebView {
			webView.scrollView.flashScrollIndicators()
		}
	}
	override func viewDidDisappear(_ animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
}
