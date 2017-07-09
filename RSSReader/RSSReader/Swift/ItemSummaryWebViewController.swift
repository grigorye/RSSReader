//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderAppConfig
import RSSReaderData
import SafariServices
import UIKit
import CoreData

var hideBarsOnSwipe = false

let markAsReadTimeInterval = TimeInterval(1)

extension TypedUserDefaults {
	@NSManaged var zoom: Float
}

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var webView: UIWebView!
	var savedToolbarItems: [UIBarButtonItem]!
	@IBOutlet var markAsFavoriteBarButtonItem: UIBarButtonItem!
	@IBOutlet var unmarkAsFavoriteBarButtonItem: UIBarButtonItem!
	@objc dynamic var item: Item!
	var markAsOpenAndReadTimer: Timer?
	@objc func markAsOpenAndRead() {
		item.lastOpenedDate = Date()
		if !item.markedAsRead {
			item.markedAsRead = true
		}
	}
	// MARK:-
	var summaryHTMLString: String {
		let htmlTemplateURL = R.file.itemSummaryTemplateHtml.url()!
		let htmlTemplate = try! NSString(contentsOf: htmlTemplateURL, encoding: String.Encoding.utf8.rawValue)
		let htmlString =
			htmlTemplate
				.replacingOccurrences(of: "$$Zoom$$", with: "\(defaults.zoom)")
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
		retrieveReadableHTMLFromURL(url) { (arg) in
			let (HTMLString, error) = arg
			DispatchQueue.main.async {
				if let error = error {
					self.track(.unableToExpand(due: x$(error)))
					return
				}
				guard let HTMLString = HTMLString else {
					assert(false)
					return
				}
				do {
					try self.loadHTMLString(HTMLString, ignoringExisting: true)
				}
				catch {
					self.track(.unableToExpand(due: x$(error)))
				}
			}
		}
	}
	// MARK: -
	var itemMarkedAsReadKVOBinding: Any?
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		self.savedToolbarItems = self.toolbarItems!
		scheduledForViewWillAppear += [{
			do {
				try self.loadHTMLString(self.summaryHTMLString, ignoringExisting: false)
			}
			catch {
				self.track(.unableToLoadSummary(due: x$(error)))
			}
		}]
	}
	// MARK: -
	var managesBarVisiblity = false {
		willSet {
			precondition(newValue != managesBarVisiblity)
			if hideBarsOnSwipe {
				x$(self).navigationController?.hidesBarsOnSwipe = x$(newValue)
			}
		}
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [Any]()
	var scheduledForViewWillAppear = ScheduledHandlers()
	override func viewWillAppear(_ animated: Bool) {
		scheduledForViewWillAppear.perform()
		viewDidDisappearRetainedObjects += [self.observe(\.item.markedAsFavorite, options: .initial) { [unowned self] (_, _) in
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
		scheduledForViewWillDisappear += [{
			self.managesBarVisiblity = false
		}]
		self.markAsOpenAndReadTimer = Timer.scheduledTimer(timeInterval: markAsReadTimeInterval, target: self, selector: #selector(self.markAsOpenAndRead), userInfo: nil, repeats: false)
	}
	var scheduledForViewWillDisappear = ScheduledHandlers()
	override func viewWillDisappear(_ animated: Bool) {
		scheduledForViewWillDisappear.perform()
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
	func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if navigationType == .linkClicked {
			let url = request.url!
			let application = UIApplication.shared
			if #available(iOS 10.0, *) {
				application.open(url, options: [:], completionHandler: nil)
			} else {
				application.openURL(url)
			}
			return false
		}
		else {
			return true
		}
	}
	func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
		x$(error)
	}
	func webViewDidFinishLoad(_ webView: UIWebView) {
		x$(webView)
	}
}
