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
	@IBAction func action(sender: AnyObject?, event: UIEvent?) {
		let activityViewController: UIViewController = {
			let currentViewController = (self.pageViewController!.viewControllers.first as! ItemSummaryWebViewController)
			let item = currentViewController.item
			let href = item.canonical!.first!["href"]!
			let url = NSURL(string: href)!
			let activityItems = [url, item]
			return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		}()
		self.pageViewController!.navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
	}
	@IBAction func expand(sender: AnyObject?, event: UIEvent?) {
		let currentViewController = (self.pageViewController!.viewControllers.first as! ItemSummaryWebViewController)
		let item = currentViewController.item
		let href = item.canonical!.first!["href"]!
		let url = NSURL(string: href)!
		let readability = DZReadability(URLToDownload: url, options: nil) { sender, content, error in
			void(trace("error", error))
			currentViewController.loadHTMLString(content, ignoringExisting: true)
		}
        readability.start()
	}
	// MARK:-
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
		let pendingViewController = pendingViewControllers.first as! ItemSummaryWebViewController
		let currentViewController = pageViewController.viewControllers.first as! ItemSummaryWebViewController
		dispatch_async(dispatch_get_main_queue()) {
			pendingViewController.view.frame = currentViewController.view.frame
			pendingViewController.webView.frame = currentViewController.webView.frame
		}
	}
}
