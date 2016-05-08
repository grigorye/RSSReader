//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import GEKeyPaths
import SafariServices
import UIKit
import CoreData

var hideBarsOnSwipe = false

let markAsReadTimeInterval = NSTimeInterval(1)

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var webView: UIWebView!
	var savedToolbarItems: [UIBarButtonItem]!
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
					$(uploadReadStateError)
					dispatch_sync(dispatch_get_main_queue()) {
						let message = String.localizedStringWithFormat(NSLocalizedString("Failed to mark as read. %@", comment: ""), (uploadReadStateError as NSError).localizedDescription)
						self.presentErrorMessage(message)
					}
				}
			})
		}
	}
	// MARK:-
	var summaryHTMLString: String {
		let bundle = NSBundle.mainBundle()
		let htmlTemplateURL = bundle.URLForResource("ItemSummaryTemplate", withExtension: "html")!
		let htmlTemplate = try! NSString(contentsOfURL: htmlTemplateURL, encoding: NSUTF8StringEncoding)
		let htmlString =
			htmlTemplate
				.stringByReplacingOccurrencesOfString("$$Summary$$", withString: item.summary!)
				.stringByReplacingOccurrencesOfString("$$Title$$", withString: item.title)
		return htmlString
	}
	// MARK:-
	var directoryInCaches: String {
		let directoryInCaches = (item.objectID.URIRepresentation().path! as NSString).substringFromIndex(1)
		return directoryInCaches
	}
	// MARK:-
	var storedHTMLURL: NSURL {
		let pathInCaches = (directoryInCaches as NSString).stringByAppendingPathComponent("text.html")
		let storedHTMLURL = NSURL(string: pathInCaches, relativeToURL: userCachesDirectoryURL)!
		return storedHTMLURL
	}
	// MARK:-
	func regenerateStoredHTMLFromString(HTMLString: String) throws {
		let fileManager = NSFileManager.defaultManager()
		try fileManager.createDirectoryAtURL(storedHTMLURL.URLByDeletingLastPathComponent!, withIntermediateDirectories: true, attributes: nil)
		try HTMLString.writeToURL(storedHTMLURL, atomically: true, encoding: NSUTF8StringEncoding)
	}
	func loadHTMLString(HTMLString: String, ignoringExisting: Bool) throws {
		let webView = self.webView
		if let _ = webView.request where !ignoringExisting {
			webView.reload()
		}
		else {
			if _1 {
				try self.regenerateStoredHTMLFromString(HTMLString)
				let request = NSURLRequest(URL: storedHTMLURL.fileReferenceURL()!)
				webView.loadRequest(request)
			}
			else {
				let bundle = NSBundle.mainBundle()
				self.webView.loadHTMLString(HTMLString, baseURL: bundle.resourceURL)
			}
		}
	}
	// MARK: -
	@IBAction func markAsFavorite(sender: AnyObject?, event: UIEvent?) {
		item.markedAsFavorite = true
		rssSession!.uploadTag(canonicalFavoriteTag, mark: true, forItem: item, completionHandler: { uploadFavoritesStateError in
			if let uploadFavoritesStateError = uploadFavoritesStateError {
				$(uploadFavoritesStateError)
				dispatch_async(dispatch_get_main_queue()) {
					self.presentErrorMessage(NSLocalizedString("Failed to mark as favorite.", comment: ""))
				}
			}
		})
	}
	@IBAction func unmarkAsFavorite(sender: AnyObject?, event: UIEvent?) {
		item.markedAsFavorite = false
		rssSession!.uploadTag(canonicalFavoriteTag, mark: false, forItem: item, completionHandler: { uploadFavoritesStateError in
			if let uploadFavoritesStateError = uploadFavoritesStateError {
				$(uploadFavoritesStateError)
				dispatch_async(dispatch_get_main_queue()) {
					self.presentErrorMessage(NSLocalizedString("Failed to unmark as favorite.", comment: ""))
				}
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
	@IBAction func openInReader(sender: AnyObject?, event: UIEvent?) {
		let url: NSURL = {
			if _1 {
				let item = self.item
				let href = item.canonical!.first!["href"]!
				return NSURL(string: href)!
			}
			else {
				try! self.regenerateStoredHTMLFromString(self.summaryHTMLString)
				return self.storedHTMLURL
			}
		}()
		let safariViewController = SFSafariViewController(URL: url, entersReaderIfAvailable: true)
		self.presentViewController(safariViewController, animated: true, completion: nil)
	}
	@IBAction func expand(sender: AnyObject?, event: UIEvent?) {
		let item = self.item
		let href = item.canonical!.first!["href"]!
		let url = NSURL(string: href)!
		retrieveReadableHTMLFromURL(url) { HTMLString, error in
			dispatch_async(dispatch_get_main_queue()) {
				guard let HTMLString = HTMLString where nil == error else {
					$(error)
					let message = NSLocalizedString("Unable to expand", comment: "")
					self.presentErrorMessage(message)
					return
				}
				do {
					try self.loadHTMLString(HTMLString, ignoringExisting: true)
				}
				catch {
					$(error)
					let message = NSLocalizedString("Unable to expand", comment: "")
					self.presentErrorMessage(message)
				}
			}
		}
	}
	// MARK: -
	var blocksScheduledForViewWillAppear = [Handler]()
	var blocksScheduledForViewWillDisappear = [Handler]()
	var itemMarkedAsReadKVOBinding: KVOBinding?
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		self.savedToolbarItems = self.toolbarItems!
		blocksScheduledForViewWillAppear += [{
			do {
				try self.loadHTMLString(self.summaryHTMLString, ignoringExisting: false)
			}
			catch {
				self.presentErrorMessage(NSLocalizedString("Unable to load summary", comment: ""))
			}
		}]
	}
	// MARK: -
	var managesBarVisiblity = false {
		willSet {
			precondition(newValue != managesBarVisiblity)
			if hideBarsOnSwipe {
				$(self).navigationController?.hidesBarsOnSwipe = $(newValue)
			}
		}
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	override func viewWillAppear(animated: Bool) {
		blocksScheduledForViewWillAppear.forEach { $0() }
		blocksScheduledForViewWillAppear = []
		viewDidDisappearRetainedObjects += [KVOBinding(self•{$0.item.markedAsFavorite}, options: .Initial) { [unowned self] change in
			let excludedBarButtonItem = self.item.markedAsFavorite ? self.markAsFavoriteBarButtonItem : self.unmarkAsFavoriteBarButtonItem
			let toolbarItems = self.savedToolbarItems.filter {
				return $0 != excludedBarButtonItem
			}
			self.toolbarItems = (toolbarItems)
		}]
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.managesBarVisiblity = true
		blocksScheduledForViewWillDisappear += [{
			self.managesBarVisiblity = false
		}]
		self.markAsOpenAndReadTimer = NSTimer.scheduledTimerWithTimeInterval(markAsReadTimeInterval, target: self, selector: #selector(ItemSummaryWebViewController.markAsOpenAndRead), userInfo: nil, repeats: false)
	}
	override func viewWillDisappear(animated: Bool) {
		blocksScheduledForViewWillDisappear.forEach { $0() }
		blocksScheduledForViewWillDisappear = []
		super.viewWillDisappear(animated)
		self.markAsOpenAndReadTimer?.invalidate()
	}
	override func viewDidDisappear(animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
	// MARK: -
	override func prefersStatusBarHidden() -> Bool {
		return navigationController?.navigationBarHidden ?? false
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
		$(error)
	}
	func webViewDidFinishLoad(webView: UIWebView) {
		$(webView)
	}
}
