//
//  ItemsPageViewControllerDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class ItemsPageViewControllerDelegate: NSObject, UIPageViewControllerDelegate {
	@IBOutlet weak var pageViewController: UIPageViewController?
	@IBAction func openInBrowser(sender: AnyObject?, event: UIEvent?) {
		let currentViewController = pageViewController!.viewControllers.first as ItemSummaryWebViewController
		UIApplication.sharedApplication().sendAction("openInBrowser", to: currentViewController, from: sender, forEvent: event)
	}
	// MARK:-
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
		let pendingViewController = pendingViewControllers.first as ItemSummaryWebViewController
		let currentViewController = pageViewController.viewControllers.first as ItemSummaryWebViewController
		dispatch_async(dispatch_get_main_queue()) {
			pendingViewController.view.frame = currentViewController.view.frame
			pendingViewController.webView.frame = currentViewController.webView.frame
		}
	}
}
