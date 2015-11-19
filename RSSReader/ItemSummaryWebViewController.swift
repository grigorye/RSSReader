//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit
import CoreData

var hideBarsOnSwipe = false

let markAsReadTimeInterval = NSTimeInterval(1)

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var webView: UIWebView!
	var savedRightBarButtonItems: [UIBarButtonItem]!
	@IBOutlet var markAsFavoriteBarButtonItem: UIBarButtonItem!
	@IBOutlet var unmarkAsFavoriteBarButtonItem: UIBarButtonItem!
	dynamic var item: Item!
	var markAsOpenAndReadTimer: NSTimer?
	func markAsOpenAndRead() {
		item.lastOpenedDate = NSDate()
		if !item.markedAsRead {
			item.markedAsRead = true
			rssSession!.uploadTag(canonicalReadTag, mark: true, forItem: item, completionHandler: { uploadReadStateError in
				if let uploadReadStateError = uploadReadStateError {
					$(uploadReadStateError).$()
				}
			})
		}
	}
	func loadHTMLString(HTMLString: String, ignoringExisting: Bool) throws {
		let webView = self.webView
		let bundle = NSBundle.mainBundle()
		let htmlTemplateURL = bundle.URLForResource("ItemSummaryTemplate", withExtension: "html")!
		let htmlTemplate = try! NSString(contentsOfURL: htmlTemplateURL, encoding: NSUTF8StringEncoding)
		let htmlString =
			htmlTemplate
				.stringByReplacingOccurrencesOfString("$$Summary$$", withString: HTMLString)
				.stringByReplacingOccurrencesOfString("$$Title$$", withString: item.title!)
		if let _ = webView.request where !ignoringExisting {
			webView.reload()
		}
		else {
			if _1 {
				let fileManager = NSFileManager.defaultManager()
				let cachesDirectoryURL = try! fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
				let directoryInCaches = (item.objectID.URIRepresentation().path! as NSString).substringFromIndex(1)
				let pathInCaches = (directoryInCaches as NSString).stringByAppendingPathComponent("summary.html")
				let storedHTMLURL = NSURL(string: pathInCaches, relativeToURL: cachesDirectoryURL)!
				try fileManager.createDirectoryAtURL(cachesDirectoryURL.URLByAppendingPathComponent(directoryInCaches), withIntermediateDirectories: true, attributes: nil)
				try htmlString.writeToURL(storedHTMLURL, atomically: true, encoding: NSUTF8StringEncoding)
				let request = NSURLRequest(URL: storedHTMLURL.fileReferenceURL()!)
				webView.loadRequest(request)
			}
			else {
				self.webView.loadHTMLString(htmlString, baseURL: bundle.resourceURL)
			}
		}
	}
	// MARK: -
	@IBAction func markAsFavorite(sender: AnyObject?, event: UIEvent?) {
		item.markedAsFavorite = true
		rssSession!.uploadTag(canonicalFavoriteTag, mark: true, forItem: item, completionHandler: { uploadFavoritesStateError in
			if let uploadFavoritesStateError = uploadFavoritesStateError {
				$(uploadFavoritesStateError).$()
				self.presentErrorMessage(NSLocalizedString("Failed to mark as favorite.", comment: ""))
			}
		})
	}
	@IBAction func unmarkAsFavorite(sender: AnyObject?, event: UIEvent?) {
		item.markedAsFavorite = false
		rssSession!.uploadTag(canonicalFavoriteTag, mark: false, forItem: item, completionHandler: { uploadFavoritesStateError in
			if let uploadFavoritesStateError = uploadFavoritesStateError {
				$(uploadFavoritesStateError).$()
				self.presentErrorMessage(NSLocalizedString("Failed to unmark as favorite.", comment: ""))
			}
		})
	}
	@IBAction func action(sender: AnyObject?, event: UIEvent?) {
		let activityViewController: UIViewController = {
			let item = self.item
			let href = item.canonical!.first!["href"]!
			let url = NSURL(string: href)!
			let activityItems = [url, item]
			return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		}()
		self.presentViewController(activityViewController, animated: true, completion: nil)
	}
	@IBAction func expand(sender: AnyObject?, event: UIEvent?) {
		let item = self.item
		let href = item.canonical!.first!["href"]!
		let url = NSURL(string: href)!
		let dataTask = progressEnabledURLSessionTaskGenerator.textTaskForHTTPRequest(NSURLRequest(URL: url)) { text, error in
			dispatch_async(dispatch_get_main_queue()) {
				if let error = error {
					$(error).$()
					self.presentErrorMessage(NSLocalizedString("Failed to expand.", comment: ""))
				}
				else {
#if false
					let readability = DZReadability(URL: url, rawDocumentContent: text, options: nil) { sender, content, error in
						if let error = error {
							$(error).$()
							self.presentErrorMessage(NSLocalizedString("Unable to expand", comment: ""))
						}
						else {
							do {
								try self.loadHTMLString(content, ignoringExisting: true)
							}
							catch {
								$(error).$()
								self.presentErrorMessage(NSLocalizedString("Unable to load", comment: ""))
							}
						}
					}
					readability.start()
#endif
				}
			}
		}!
		dataTask.resume()
	}
	// MARK: -
	var blocksScheduledForViewWillAppear = [Handler]()
	var itemMarkedAsReadKVOBinding: KVOBinding?
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		self.savedRightBarButtonItems = self.navigationItem.rightBarButtonItems!
		blocksScheduledForViewWillAppear += [{
			let item = self.item
			do {
				try self.loadHTMLString(item.summary!, ignoringExisting: false)
			}
			catch {
				self.presentErrorMessage(NSLocalizedString("Unable to load summary", comment: ""))
			}
		}]
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	override func viewWillAppear(animated: Bool) {
		for i in blocksScheduledForViewWillAppear { i() }
		blocksScheduledForViewWillAppear = []
		viewDidDisappearRetainedObjects += [KVOBinding(self•{$0.item.markedAsFavorite}, options: .Initial) { [unowned self] change in
			let excludedBarButtonItem = self.item.markedAsFavorite ? self.markAsFavoriteBarButtonItem : self.unmarkAsFavoriteBarButtonItem
			let rightBarButtonItems = self.savedRightBarButtonItems.filter {
				return $0 != excludedBarButtonItem
			}
			self.navigationItem.rightBarButtonItems = $(rightBarButtonItems).$()
		}]
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.markAsOpenAndReadTimer = NSTimer.scheduledTimerWithTimeInterval(markAsReadTimeInterval, target: self, selector: "markAsOpenAndRead", userInfo: nil, repeats: false)
	}
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.markAsOpenAndReadTimer?.invalidate()
	}
	override func viewDidDisappear(animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
	override func willMoveToParentViewController(parent: UIViewController?) {
		$(parent).$()
		super.willMoveToParentViewController(parent)
		if hideBarsOnSwipe {
			self.navigationController?.hidesBarsOnSwipe = nil != parent
		}
	}
	// MARK: -
	override func prefersStatusBarHidden() -> Bool {
		return navigationController!.navigationBarHidden;
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
		let item = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.itemObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Item
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
	func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
		$(error).$()
	}
	func webViewDidFinishLoad(webView: UIWebView) {
		$(webView).$()
	}
}
