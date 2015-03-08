//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData.NSManagedObjectContext

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
		item.lastOpenedDate = NSDate()
	}
	func loadHTMLString(HTMLString: String, ignoringExisting: Bool) {
		let webView = self.webView
		let bundle = NSBundle.mainBundle()
		let htmlTemplateURL = bundle.URLForResource("ItemSummaryTemplate", withExtension: "html")!
		var htmlTemplateLoadError: NSError?
		let htmlTemplate = NSString(contentsOfURL: htmlTemplateURL, encoding: NSUTF8StringEncoding, error: &htmlTemplateLoadError)!
		let htmlString =
			htmlTemplate
				.stringByReplacingOccurrencesOfString("$$Summary$$", withString: HTMLString)
				.stringByReplacingOccurrencesOfString("$$Title$$", withString: item.title!)
		if let webViewRequest = webView.request where !ignoringExisting {
			webView.reload()
		}
		else {
			if _1 {
				let fileManager = NSFileManager.defaultManager()
				var cachesDirectoryCreationError: NSError?
				let cachesDirectoryURL = fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true, error: &cachesDirectoryCreationError)!
				assert(nil == cachesDirectoryCreationError)
				let directoryInCaches = (item.objectID.URIRepresentation().path! as NSString).substringFromIndex(1)
				let pathInCaches = directoryInCaches.stringByAppendingPathComponent("summary.html")
				let storedHTMLURL = NSURL(string: pathInCaches, relativeToURL: cachesDirectoryURL)!
				var storedHTMLDirectoryCreationError: NSError?
				fileManager.createDirectoryAtURL(cachesDirectoryURL.URLByAppendingPathComponent(directoryInCaches), withIntermediateDirectories: true, attributes: nil, error: &storedHTMLDirectoryCreationError)
				assert(nil == storedHTMLDirectoryCreationError)
				var htmlWriteError: NSError?
				htmlString.writeToURL(storedHTMLURL, atomically: true, encoding: NSUTF8StringEncoding, error: &htmlWriteError)
				assert(nil == htmlWriteError)
				let request = NSURLRequest(URL: storedHTMLURL.fileReferenceURL()!)
				webView.loadRequest(request)
			}
			else {
				self.webView.loadHTMLString(htmlString, baseURL: bundle.resourceURL)
			}
		}
	}
	// MARK: -
	var blocksScheduledForViewWillAppear = [Handler]()
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		blocksScheduledForViewWillAppear += [{
			let item = self.item
			self.loadHTMLString(item.summary!, ignoringExisting: false)
		}]
	}
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		for i in blocksScheduledForViewWillAppear { i() }
		blocksScheduledForViewWillAppear = []
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if !self.item.markedAsRead {
			self.markAsReadTimer = NSTimer.scheduledTimerWithTimeInterval(markAsReadTimeInterval, target: self, selector: "markAsRead", userInfo: nil, repeats: false)
		}
	}
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.markAsReadTimer?.invalidate()
	}
	// MARK: - State Preservation and Restoration
	enum Restorable: String {
		case itemObjectID = "itemObjectID"
	}
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		item.encodeObjectIDWithCoder(coder, key: Restorable.itemObjectID.rawValue)
	}
	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)
		let item = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.itemObjectID.rawValue, managedObjectContext: self.mainQueueManagedObjectContext) as! Item
		self.item = item
	}
}

class ItemSummaryWebViewDelegate: NSObject, UIWebViewDelegate {
	var blocksScheduledOnWebViewDidFinishLoad = [Handler]()
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if navigationType == .LinkClicked {
			let url = request.URL!
			UIApplication.sharedApplication().openURL(url)
			return false
		}
		else {
			return true
		}
	}
	func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
		trace("error", error)
	}
	func webViewDidFinishLoad(webView: UIWebView) {
		trace("webView", webView)
	}
}
