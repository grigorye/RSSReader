//
//  ItemsListViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

extension Item {
	class func keyPathsForValuesAffectingItemListSectionName() -> NSSet {
		return NSSet(array: ["date", "loadDate"])
	}
	func itemsListSectionName() -> String {
		let timeInterval = self.date.timeIntervalSinceDate(self.date)
		if timeInterval < 24 * 3600 {
			return ""
		}
		else if timeInterval < 7 * 24 * 3600 {
			return "Last Week"
		}
		else if timeInterval < 30 * 7 * 24 * 3600 {
			return "Last Month"
		}
		else if timeInterval < 365 * 7 * 24 * 3600 {
			return "Last Year"
		}
		else {
			return "More than Year Ago"
		}
	}
}

let dateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Abbreviated
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.allowedUnits = .CalendarUnitMinute | .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitWeekOfMonth | .CalendarUnitDay | .CalendarUnitHour
	return $;
}()

class ItemsListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	var folder: Container!
	private var continuation: NSString?
	private var loadDate: NSDate!
	private var loadInProgress = false
	private var lastLoadedItem: Item?
	private var loadCompleted = false
	private var loadError: NSError?
	private var tableFooterView: UIView?
	private var indexPathForTappedAccessoryButton: NSIndexPath?
	private var showUnreadOnly: Bool {
		return _1 ? false : defaults.showUnreadOnly
	}
	private var unreadOnlyFilterPredicate: NSPredicate {
		if showUnreadOnly {
			return NSPredicate(format: "SUBQUERY(categories, $x, $x.id ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}
	private lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let folder = self.folder
			let $ = NSFetchRequest(entityName: Item.entityName())
			$.sortDescriptors = [
				NSSortDescriptor(key: "date", ascending: false),
			]
			$.predicate = NSCompoundPredicate.andPredicateWithSubpredicates([
				NSPredicate(format: "(subscription == %@) or (categories contains %@)", argumentArray: [folder, folder]),
				self.unreadOnlyFilterPredicate
			])
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: _1 ? nil : "itemsListSectionName", cacheName: nil)
		$.delegate = self
		return $
	}()
	// MARK: -
	private func loadMore(completionHandler: (loadDateDidChange: Bool) -> Void) {
		assert(!loadInProgress, "")
		assert(!loadCompleted, "")
		assert(nil == loadError, "")
		if nil == self.continuation {
			self.loadDate = NSDate()
		}
		let loadDate = self.loadDate
		loadInProgress = true
		let excludedCategory: Folder? = showUnreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: self.mainQueueManagedObjectContext) : nil
		rssSession.streamContents(self.folder, excludedCategory: excludedCategory, continuation: self.continuation, loadDate: self.loadDate) { continuation, items, streamError in
			dispatch_async(dispatch_get_main_queue()) {
				if loadDate != self.loadDate {
					// Ignore results from previous sessions.
					completionHandler(loadDateDidChange: true)
					return
				}
				if let streamError = streamError {
					self.loadError = trace("streamError", streamError)
				}
				else {
					if let lastItemInCompletion = items.last {
						let managedObjectContext = self.fetchedResultsController.managedObjectContext
						self.lastLoadedItem = (managedObjectContext.objectWithID(lastItemInCompletion.objectID) as Item)
					}
					self.continuation = continuation
					if nil == continuation {
						self.loadCompleted = true
						UIView.animateWithDuration(0.4) {
							self.tableView.tableFooterView = nil
						}
					}
				}
				self.loadInProgress = false
				completionHandler(loadDateDidChange: false)
				self.loadMoreIfNecessary()
			}
		}
	}
	private func loadMoreIfNecessary() {
		let shouldLoadMore: Bool = {
			if (self.loadInProgress || self.loadCompleted || self.loadError != nil) {
				return false
			}
			if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() {
				if let lastVisibleIndexPath = indexPathsForVisibleRows.last as NSIndexPath? {
					let numberOfItemsToPreload = 10
					let barrierIndexPath = NSIndexPath(forRow: lastVisibleIndexPath.row + numberOfItemsToPreload, inSection: lastVisibleIndexPath.section)
					let indexPathForLastLoadedItem : NSIndexPath = {
						if let lastLoadedItem = self.lastLoadedItem {
							return self.fetchedResultsController.indexPathForObject(lastLoadedItem)!
						}
						else {
							return NSIndexPath(forRow: 0, inSection: 0)
						}
					}()
					return indexPathForLastLoadedItem.compare(barrierIndexPath) == .OrderedAscending
				}
				return true
			}
			return false
		}()
		if shouldLoadMore {
			self.loadMore { loadDateDidChange in
			}
		}
	}
	@IBAction private func refresh(sender: AnyObject!) {
		if loadInProgress && trace("nil == continuation", nil == continuation) {
			self.refreshControl?.endRefreshing()
		}
		else {
			self.loadCompleted = false
			self.continuation = nil
			self.loadInProgress = false
			self.loadError = nil
			self.loadMore { loadDateDidChange in
				if !loadDateDidChange {
					void(self.refreshControl?.endRefreshing())
				}
			}
			UIView.animateWithDuration(0.4) {
				self.tableView.tableFooterView = self.tableFooterView
			}
		}
	}
	@IBAction private func markAllAsRead(sender: AnyObject!) {
		let items = (self.folder.valueForKey("items") as NSSet).allObjects as [Item]
		for i in items {
			i.markedAsRead = true
		}
		rssSession.markAllAsRead(self.folder) { error in
			void(trace("error", error))
		}
	}
	@IBAction private func action(sender: AnyObject?) {
		let activityViewController: UIViewController = {
			let activityItems = [self.folder]
			return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		}()
		self.navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
	}
	// MARK: -
	private func itemForIndexPath(indexPath: NSIndexPath) -> Item {
		return self.fetchedResultsController.fetchedObjects![indexPath.row] as Item
	}
	private func selectedItem() -> Item {
		return self.itemForIndexPath(self.tableView.indexPathForSelectedRow()!)
	}
	// MARK: -
	private func configureCell(rawCell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let cell = rawCell as ItemTableViewCell
		let item = fetchedResultsController.objectAtIndexPath(indexPath) as Item
		if let titleLabel = cell.titleLabel {
			titleLabel.text = item.title ?? item.id.lastPathComponent
		}
		if let subtitleLabel = cell.subtitleLabel {
			let timeIntervalFormatted = (nil == NSClassFromString("NSDateComponentsFormatter")) ? "x" : dateComponentsFormatter.stringFromDate(item.date, toDate: loadDate) ?? ""
			subtitleLabel.text = "\(timeIntervalFormatted)"
			if _0 {
			subtitleLabel.textColor = item.markedAsRead ? nil : UIColor.redColor()
			}
		}
		if let readMarkLabel = cell.readMarkLabel {
			readMarkLabel.hidden = item.markedAsRead
		}
	}
	// MARK: -
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		self.tableView.beginUpdates()
	}
	private let rowAnimation = UITableViewRowAnimation.None
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
		case .Insert:
			tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
		case .Delete:
			tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
		default:
			abort()
		}
	}
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		let tableView = self.tableView!
		switch type {
		case .Insert:
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
		case .Delete:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
		case .Update:
			if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
				self.configureCell(cell, atIndexPath: indexPath!)
			}
		case .Move:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
		}
	}
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		(_1 ? UIView.performWithoutAnimation : invoke) {
			self.tableView.endUpdates()
		}
	}
	// MARK: -
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return fetchedResultsController.sections!.count
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo).numberOfObjects
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return (fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo).name
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.ReuseIdentifiers.Item, forIndexPath: indexPath) as UITableViewCell
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		self.loadMoreIfNecessary()
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowPages:
			let pageViewController = segue.destinationViewController as UIPageViewController
			let itemsPageViewControllerDataSource: ItemsPageViewControllerDataSource = {
				let $ = pageViewController.dataSource as ItemsPageViewControllerDataSource
				$.items = self.fetchedResultsController.fetchedObjects as [Item]
				return $
			}()
			let initialViewController = itemsPageViewControllerDataSource.viewControllerForItem(self.selectedItem(), storyboard: pageViewController.storyboard!)
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				pageViewController.edgesForExtendedLayout = .None
			}
			pageViewController.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
		default:
			abort()
		}
	}
	// MARK: - State Preservation and Restoration
	private enum Restorable: String {
		case folderObjectID = "folderObjectID"
	}
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		folder.encodeObjectIDWithCoder(coder, key: Restorable.folderObjectID.rawValue)
	}
	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)
		let folder = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.folderObjectID.rawValue, managedObjectContext: self.mainQueueManagedObjectContext) as Container
		self.folder = folder
	}
	// MARK: -
	var blocksDelayedTillViewWillAppear = [Handler]()
	override func viewWillAppear(animated: Bool) {
		for i in blocksDelayedTillViewWillAppear {
			i()
		}
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		blocksDelayedTillViewWillAppear += [{
			var fetchError: NSError?
			self.fetchedResultsController.performFetch(&fetchError)
			assert(nil == fetchError, "")
			self.title = (self.folder as Titled).visibleTitle
			return
		}]
		self.tableFooterView = tableView.tableFooterView
	}
}
