//
//  ItemsPageViewControllerDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class ItemsPageViewControllerDelegate: NSObject, UIPageViewControllerDelegate {
	@IBOutlet weak var pageViewController: ItemsPageViewController!
	private var pendingViewController: UIViewController!
	// MARK:-
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
		let pendingViewController = pendingViewControllers.first as! ItemSummaryWebViewController
		let currentViewController = pageViewController.viewControllers.first as! ItemSummaryWebViewController
		self.pendingViewController = pendingViewController
		dispatch_async(dispatch_get_main_queue()) {
			pendingViewController.view.frame = currentViewController.view.frame
			pendingViewController.webView.frame = currentViewController.webView.frame
		}
	}
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
		trace("completed", completed)
		self.pageViewController.currentViewController = self.pendingViewController
		self.pendingViewController = nil
	}
}
