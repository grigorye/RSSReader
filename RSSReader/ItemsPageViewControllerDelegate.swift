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
	// MARK:-
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
		let pendingViewController = pendingViewControllers.first as! ItemSummaryWebViewController
		let currentViewController = pageViewController.viewControllers!.first as! ItemSummaryWebViewController
		dispatch_async(dispatch_get_main_queue()) {
			pendingViewController.view.frame = currentViewController.view.frame
			pendingViewController.webView.frame = currentViewController.webView.frame
		}
	}
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		$(completed).$()
		let currentViewController = pageViewController.viewControllers!.first as! ItemSummaryWebViewController
		if let webView = currentViewController.view.subviews.first as? UIWebView {
			webView.scrollView.flashScrollIndicators()
		}
		self.pageViewController.currentViewController = currentViewController
	}
}
