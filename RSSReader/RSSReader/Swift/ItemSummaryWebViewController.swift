//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import SafariServices
import UIKit
import CoreData

var hideBarsOnSwipe = false

let markAsReadTimeInterval = TimeInterval(1)

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var webView: UIWebView!
	var savedToolbarItems: [UIBarButtonItem]!
	@IBOutlet var markAsFavoriteBarButtonItem: UIBarButtonItem!
	@IBOutlet var unmarkAsFavoriteBarButtonItem: UIBarButtonItem!
	dynamic var item: Item!
	var markAsOpenAndReadTimer: Timer?
	func markAsOpenAndRead() {
		item.lastOpenedDate = Date()
		if !item.markedAsRead {
			item.markedAsRead = true
		}
	}
	// MARK:-
	var summaryHTMLString: String {
		let bundle = Bundle.main
		let htmlTemplateURL = bundle.url(forResource: "ItemSummaryTemplate", withExtension: "html")!
		let htmlTemplate = try! NSString(contentsOf: htmlTemplateURL, encoding: String.Encoding.utf8.rawValue)
		let htmlString =
			htmlTemplate
				.replacingOccurrences(of: "$$Summary$$", with: item.summary!)
				.replacingOccurrences(of: "$$Title$$", with: item.title)
		return htmlString
	}
	// MARK:-
	var directoryInCaches: String {
		let directoryInCaches = (item.objectID.uriRepresentation().path as NSString).substring(from: 1)
		return directoryInCaches
	}
	// MARK:-
	var storedHTMLURL: URL {
		let pathInCaches = (directoryInCaches as NSString).appendingPathComponent("text.html")
		let storedHTMLURL = URL(string: pathInCaches, relativeTo: userCachesDirectoryURL as URL)!
		return storedHTMLURL
	}
	// MARK:-
	func regenerateStoredHTMLFromString(_ HTMLString: String) throws {
		let fileManager = FileManager.default
		try fileManager.createDirectory(at: storedHTMLURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		try HTMLString.write(to: storedHTMLURL, atomically: true, encoding: String.Encoding.utf8)
	}
	func loadHTMLString(_ HTMLString: String, ignoringExisting: Bool) throws {
		let webView = self.webView
		if let _ = webView?.request, !ignoringExisting {
			webView?.reload()
		}
		else {
			if _1 {
				try self.regenerateStoredHTMLFromString(HTMLString)
				let request = URLRequest(url: storedHTMLURL)
				webView?.loadRequest(request)
			}
			else {
				let bundle = Bundle.main
				self.webView.loadHTMLString(HTMLString, baseURL: bundle.resourceURL)
			}
		}
	}
	// MARK: -
	@IBAction func markAsFavorite(_ sender: AnyObject?, event: UIEvent?) {
		item.markedAsFavorite = true
	}
	@IBAction func unmarkAsFavorite(_ sender: AnyObject?, event: UIEvent?) {
		item.markedAsFavorite = false
	}
	@IBAction func action(_ sender: AnyObject?, event: UIEvent?) {
		let activityViewController: UIViewController = {
			let item = self.item!
			let href = item.canonical!.first!["href"]!
			let url = URL(string: href)!
			let activityItems: [Any] = [url, item]
			return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		}()
		self.present(activityViewController, animated: true, completion: nil)
	}
	@IBAction func openInReader(_ sender: AnyObject?, event: UIEvent?) {
		let url: URL = {
			if _1 {
				let item = self.item!
				let href = item.canonical!.first!["href"]!
				return URL(string: href)!
			}
			else {
				try! self.regenerateStoredHTMLFromString(self.summaryHTMLString)
				return self.storedHTMLURL
			}
		}()
		let safariViewController = SFSafariViewController(url: url, entersReaderIfAvailable: true)
		self.present(safariViewController, animated: true, completion: nil)
	}
	@IBAction func expand(_ sender: AnyObject?, event: UIEvent?) {
		let item = self.item!
		let href = item.canonical!.first!["href"]!
		let url = URL(string: href)!
		retrieveReadableHTMLFromURL(url) { HTMLString, error in
			DispatchQueue.main.async {
				guard let HTMLString = HTMLString, nil == error else {
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
	var viewDidDisappearRetainedObjects = [Any]()
	override func viewWillAppear(_ animated: Bool) {
		blocksScheduledForViewWillAppear.forEach { $0() }
		blocksScheduledForViewWillAppear = []
		viewDidDisappearRetainedObjects += [KVOBinding(self•#keyPath(item.markedAsFavorite), options: .initial) { [unowned self] change in
			let excludedBarButtonItem = self.item.markedAsFavorite ? self.markAsFavoriteBarButtonItem : self.unmarkAsFavoriteBarButtonItem
			let toolbarItems = self.savedToolbarItems.filter {
				return $0 != excludedBarButtonItem
			}
			self.toolbarItems = (toolbarItems)
		}]
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.managesBarVisiblity = true
		blocksScheduledForViewWillDisappear += [{
			self.managesBarVisiblity = false
		}]
		self.markAsOpenAndReadTimer = Timer.scheduledTimer(timeInterval: markAsReadTimeInterval, target: self, selector: #selector(self.markAsOpenAndRead), userInfo: nil, repeats: false)
	}
	override func viewWillDisappear(_ animated: Bool) {
		blocksScheduledForViewWillDisappear.forEach { $0() }
		blocksScheduledForViewWillDisappear = []
		super.viewWillDisappear(animated)
		self.markAsOpenAndReadTimer?.invalidate()
	}
	override func viewDidDisappear(_ animated: Bool) {
		viewDidDisappearRetainedObjects = []
		super.viewDidDisappear(animated)
	}
	// MARK: -
	override var prefersStatusBarHidden: Bool {
		return navigationController?.isNavigationBarHidden ?? false
	}
	// MARK: - State Preservation and Restoration
	enum Restorable: String {
		case itemObjectID = "itemObjectID"
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		item.encodeObjectIDWithCoder(coder, key: Restorable.itemObjectID.rawValue)
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		let item = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.itemObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Item
		self.item = item
	}
}

class ItemSummaryWebViewDelegate: NSObject, UIWebViewDelegate {
	var blocksScheduledOnWebViewDidFinishLoad = [Handler]()
	func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if navigationType == .linkClicked {
			let url = request.url!
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			return false
		}
		else {
			return true
		}
	}
	func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
		$(error)
	}
	func webViewDidFinishLoad(_ webView: UIWebView) {
		$(webView)
	}
}
