//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

let markAsReadTimeInterval = NSTimeInterval(2)

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var webView: UIWebView!
	var item: Item!
	var markAsReadTimer: NSTimer?
	func markAsRead() {
		if (!item.markedAsRead) {
			item.markedAsRead = true
			self.rssSession.uploadTag(canonicalReadTag, mark: true, forItem: item, completionHandler: { uploadReadStateError in
				if let uploadReadStateError = uploadReadStateError {
					trace("uploadReadStateError", uploadReadStateError)
				}
			})
		}
	}
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		let bundle = NSBundle.mainBundle()
		let htmlTemplateURL = bundle.URLForResource("ItemSummaryTemplate", withExtension: "html")!
		var htmlTemplateLoadError: NSError?
		let htmlTemplate = NSString(contentsOfURL: htmlTemplateURL, encoding: NSUTF8StringEncoding, error: &htmlTemplateLoadError)!
		let htmlString =
			htmlTemplate
				.stringByReplacingOccurrencesOfString("$$Summary$$", withString: item.summary!)
				.stringByReplacingOccurrencesOfString("$$Title$$", withString: item.title!)
		self.webView.loadHTMLString(htmlString, baseURL: bundle.resourceURL)
	}
	// MARK: -
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		item.lastOpenedDate = NSDate()
		self.markAsReadTimer = NSTimer.scheduledTimerWithTimeInterval(markAsReadTimeInterval, target: self, selector: "markAsRead", userInfo: nil, repeats: false)
	}
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.markAsReadTimer?.invalidate()
	}
}

class ItemSummaryWebViewDelegate: NSObject, UIWebViewDelegate {
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if navigationType == .LinkClicked {
			let url = request.URL
			UIApplication.sharedApplication().openURL(url)
			return false
		}
		else {
			return true
		}
	}
}
