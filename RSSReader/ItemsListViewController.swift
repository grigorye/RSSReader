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
	class func keyPathsForValuesAffectingItemListSectionName() -> Set<String> {
		return ["date", "loadDate"]
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
let loadAgoDateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Full
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.allowedUnits = .CalendarUnitMinute | .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitWeekOfMonth | .CalendarUnitDay | .CalendarUnitHour
	return $;
}()

class ItemsListViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation {
	var container: Container?
	lazy var containerViewState: ContainerViewState? = {
		let container = self.container!
		if let existingViewState = container.viewStates.first {
			return existingViewState
		}
		else {
			let managedObjectContext = container.managedObjectContext!
			let newViewState = NSEntityDescription.insertNewObjectForEntityForName("ContainerViewState", inManagedObjectContext: managedObjectContext) as! ContainerViewState
			newViewState.container = container
			return newViewState
		}
	}()
	private var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState!.continuation }
	}
	private var loadDate: NSDate? {
		set {
			containerViewState!.loadDate = newValue
			
			if let sectionHeaderView = self.tableView?.headerViewForSection(0) {
				sectionHeaderView.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 0)?.uppercaseString
			}
		}
		get { return containerViewState!.loadDate }
	}
	private var lastLoadedItem: Item? {
		set { containerViewState!.lastLoadedItem = newValue }
		get { return containerViewState!.lastLoadedItem }
	}
	private var loadCompleted: Bool {
		set { containerViewState!.loadCompleted = newValue }
		get { return containerViewState!.loadCompleted }
	}
	private var loadError: NSError? {
		set { containerViewState!.loadError = newValue }
		get { return containerViewState!.loadError }
	}
	//
	private var loadInProgress = false
	private var nowDate: NSDate!
	private var tableFooterView: UIView?
	private var indexPathForTappedAccessoryButton: NSIndexPath?
	private var showUnreadOnly: Bool {
		return _1 ? false : defaults.showUnreadOnly
	}
	private var unreadOnlyFilterPredicate: NSPredicate {
		if showUnreadOnly {
			return NSPredicate(format: "SUBQUERY(categories, $x, $x.streamID ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}
	private lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let container = self.container
			let $ = NSFetchRequest(entityName: Item.entityName())
			$.sortDescriptors = [
				NSSortDescriptor(key: "date", ascending: false),
			]
			$.predicate = NSCompoundPredicate.andPredicateWithSubpredicates([
				container! is Subscription ? NSPredicate(format: "(subscription == %@)", argumentArray: [container!]) : NSPredicate(format: "(categories contains %@)", argumentArray: [container!]),
				self.unreadOnlyFilterPredicate
			])
			$.fetchBatchSize = 20
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: _1 ? nil : "itemsListSectionName", cacheName: nil)
		$.delegate = self
		return $
	}()
	// MARK: -
	private func loadMore(completionHandler: (loadDateDidChange: Bool) -> Void) {
		assert(!loadInProgress)
		assert(!loadCompleted)
		assert(nil == loadError)
		if nil == self.continuation {
			self.loadDate = NSDate()
		}
		let loadDate = self.loadDate
		loadInProgress = true
		let excludedCategory: Folder? = showUnreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: self.mainQueueManagedObjectContext) : nil
		rssSession!.streamContents(container!, excludedCategory: excludedCategory, continuation: self.continuation, loadDate: loadDate!) { continuation, items, streamError in
			dispatch_async(dispatch_get_main_queue()) {
				if loadDate != self.loadDate {
					// Ignore results from previous sessions.
					completionHandler(loadDateDidChange: true)
					return
				}
				if let streamError = streamError {
					self.loadError = trace("streamError", streamError)
					presentErrorMessage(NSLocalizedString("Failed to load more.", comment: ""))
				}
				else {
					if let lastItemInCompletion = items.last {
						let managedObjectContext = self.fetchedResultsController.managedObjectContext
						self.lastLoadedItem = (managedObjectContext.objectWithID(lastItemInCompletion.objectID) as! Item)
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
				if let lastLoadedItem = self.lastLoadedItem {
					let lastVisibleIndexPath = indexPathsForVisibleRows.last as! NSIndexPath
					let numberOfItemsToPreload = 10
					let barrierIndexPath = NSIndexPath(forRow: notrace("lastVisibleIndexPath", lastVisibleIndexPath).row + numberOfItemsToPreload, inSection: lastVisibleIndexPath.section)
					let indexPathForLastLoadedItem = self.fetchedResultsController.indexPathForObject(lastLoadedItem)!
					return notrace("indexPathForLastLoadedItem.compare(barrierIndexPath) == .OrderedAscending", notrace("indexPathForLastLoadedItem", indexPathForLastLoadedItem).compare(notrace("barrierIndexPath", barrierIndexPath)) == .OrderedAscending)
				}
				else {
					return true
				}
			}
			return false
		}()
		if notrace("shouldLoadMore", shouldLoadMore) {
			self.loadMore { loadDateDidChange in
			}
		}
	}
	@IBAction private func refresh(sender: AnyObject!) {
		let refreshControl = self.refreshControl!
		if loadInProgress && trace("nil == continuation", nil == continuation) {
			refreshControl.endRefreshing()
		}
		else {
			self.loadCompleted = false
			self.continuation = nil
			self.loadInProgress = false
			self.loadError = nil
			self.loadMore { loadDateDidChange in
				if !loadDateDidChange {
					refreshControl.endRefreshing()
				}
			}
			UIView.animateWithDuration(0.4) {
				self.tableView.tableFooterView = self.tableFooterView
			}
		}
	}
	@IBAction private func markAllAsRead(sender: AnyObject!) {
		let items = (self.container as! ItemsOwner).ownItems
		for i in items {
			i.markedAsRead = true
		}
		rssSession!.markAllAsRead(container!) { error in
			void(trace("error", error))
			dispatch_async(dispatch_get_main_queue()) {
				presentErrorMessage(NSLocalizedString("Failed to mark all as read.", comment: ""))
			}
		}
	}
	@IBAction private func action(sender: AnyObject?) {
		let activityViewController = UIActivityViewController(activityItems: [container!], applicationActivities: applicationActivities)
		self.navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
	}
	// MARK: -
	private func itemForIndexPath(indexPath: NSIndexPath) -> Item {
		return self.fetchedResultsController.fetchedObjects![indexPath.row] as! Item
	}
	private func selectedItem() -> Item {
		return self.itemForIndexPath(self.tableView.indexPathForSelectedRow()!)
	}
	// MARK: -
	private func configureCell(rawCell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let cell = rawCell as! ItemTableViewCell
		let item = fetchedResultsController.objectAtIndexPath(trace("indexPath", indexPath)) as! Item
		if let titleLabel = cell.titleLabel {
			titleLabel.text = item.title ?? item.itemID.lastPathComponent
		}
		if let subtitleLabel = cell.subtitleLabel {
			let timeIntervalFormatted = (nil == NSClassFromString("NSDateComponentsFormatter")) ? "x" : dateComponentsFormatter.stringFromDate(item.date, toDate: nowDate) ?? ""
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
		trace("type", stringFromFetchedResultsChangeType(type))
		switch trace("type", type) {
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
		return (fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo).numberOfObjects
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let title: String = {
			if let loadDate = self.loadDate {
				let loadAgo = loadAgoDateComponentsFormatter.stringFromDate(loadDate, toDate: NSDate())
				return NSLocalizedString("\(loadAgo!) ago", comment: "")
			}
			else {
				return NSLocalizedString("Just now", comment: "")
			}
		}()
		return _1 ? title : (fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo).name
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Item", forIndexPath: indexPath) as! UITableViewCell
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.ShowPages, sender: self)
	}
	// MARK: -
	override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		tableView.snapHeaderToTop(animated: true)
	}
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		if nil != rssSession {
			self.loadMoreIfNecessary()
		}
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowPages:
			let pageViewController = segue.destinationViewController as! UIPageViewController
			let itemsPageViewControllerDataSource: ItemsPageViewControllerDataSource = {
				let $ = pageViewController.dataSource as! ItemsPageViewControllerDataSource
				$.items = self.fetchedResultsController.fetchedObjects! as! [Item]
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
		case containerObjectID = "containerObjectID"
	}
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		container?.encodeObjectIDWithCoder(coder, key: Restorable.containerObjectID.rawValue)
	}
	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)
		self.container = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.containerObjectID.rawValue, managedObjectContext: self.mainQueueManagedObjectContext) as! Container?
		if nil != self.container {
			var fetchError: NSError?
			fetchedResultsController.performFetch(&fetchError)
			assert(nil == fetchError)
			nowDate = NSDate()
		}
	}
	// MARK: -
    func modelIdentifierForElementAtIndexPath(indexPath: NSIndexPath, inView view: UIView) -> String {
		let item = self.itemForIndexPath(indexPath)
		return item.objectID.URIRepresentation().absoluteString!
	}
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
		let objectIDURL = NSURL(string: identifier)!
		let managedObjectContext = fetchedResultsController.managedObjectContext
		let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIDURL)!
		let object = managedObjectContext.objectWithID(objectID)
		let indexPath = fetchedResultsController.indexPathForObject(object)!
		return trace("indexPath", indexPath)
	}
	// MARK: -
	var blocksDelayedTillViewWillAppear = [Handler]()
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		nowDate = NSDate()
		for i in blocksDelayedTillViewWillAppear {
			i()
		}
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		let cellNib = UINib(nibName: "ItemTableViewCell", bundle: nil)
		tableView.registerNib(cellNib, forCellReuseIdentifier: "Item")
		blocksDelayedTillViewWillAppear += [{ [unowned self] in
			if nil == self.fetchedResultsController.fetchedObjects {
				var fetchError: NSError?
				self.fetchedResultsController.performFetch(&fetchError)
				assert(nil == fetchError)
			}
			self.title = (self.container as! Titled).visibleTitle
			let tableView = self.tableView
			if tableView.contentOffset.y == 0 {
				tableView.contentOffset = CGPoint(x: 0, y: CGRectGetHeight(tableView.tableHeaderView!.frame))
			}
		}]
		self.tableFooterView = tableView.tableFooterView
	}
}
