//
//  ItemPageViewControllerDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GETracing
import UIKit

class ItemPageViewControllerDelegate: NSObject, UIPageViewControllerDelegate {
	@IBOutlet weak var pageViewController: ItemPageViewController!
	// MARK:-
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		let pendingViewController = pendingViewControllers.first as! ItemSummaryWebViewController
		let currentViewController = pageViewController.viewControllers!.first as! ItemSummaryWebViewController
		DispatchQueue.main.async {
			pendingViewController.view.frame = currentViewController.view.frame
			pendingViewController.webView.frame = currentViewController.webView.frame
		}
	}
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		$(completed)
		let currentViewController = pageViewController.viewControllers!.first as! ItemSummaryWebViewController
		if let webView = currentViewController.view.subviews.first as? UIWebView {
			webView.scrollView.flashScrollIndicators()
		}
		self.pageViewController.currentViewController = currentViewController
	}
}
