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

private let loadAgoDateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Full
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.allowedUnits = .CalendarUnitMinute | .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitWeekOfMonth | .CalendarUnitDay | .CalendarUnitHour
	return $;
}()
private let loadAgoLongDateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Full
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.includesApproximationPhrase = true
	$.allowedUnits = .CalendarUnitMinute | .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitWeekOfMonth | .CalendarUnitDay | .CalendarUnitHour
	return $;
}()

private var fetchResultsAreAnimated: Bool {
	return defaults.fetchResultsAreAnimated
}

class ItemsListViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation {
	final var container: Container?
	private lazy var containerViewState: ContainerViewState? = {
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
	private dynamic var loadDate: NSDate? {
		set { containerViewState!.loadDate = newValue }
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
	// MARK: -
	private var loadedToolbarItems: [UIBarButtonItem]!
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var statusBarButtonItem: UIBarButtonItem!
	@IBOutlet private var filterUnreadBarButtonItem: UIBarButtonItem!
	@IBOutlet private var unfilterUnreadBarButtonItem: UIBarButtonItem!
	private var showUnreadOnly = false {
		didSet {
			fetchedResultsController_ = nil
			tableView.reloadData()
		}
	}
	private func regeneratedToolbarItems() -> [UIBarButtonItem] {
		let excludedItems = [(showUnreadOnly ?  self.filterUnreadBarButtonItem : self.unfilterUnreadBarButtonItem)!]
		let $ = loadedToolbarItems.filter { nil == find(excludedItems, $0) }
		return $
	}
	private var unreadOnlyFilterPredicate: NSPredicate {
		if showUnreadOnly {
			return NSPredicate(format: "SUBQUERY(categories, $x, $x.streamID ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}
	// MARK: -
	private func regeneratedFetchedResultsController() -> NSFetchedResultsController {
		let fetchRequest: NSFetchRequest = {
			let container = self.container
			let $ = NSFetchRequest(entityName: Item.entityName())
			$.sortDescriptors =	itemsAreSortedByLoadDate ? [NSSortDescriptor(key: "loadDate", ascending: false)] : [AnyObject]() + [
				NSSortDescriptor(key: "date", ascending: false)
			]
			$.predicate = NSCompoundPredicate.andPredicateWithSubpredicates([
				container! is Subscription ? NSPredicate(format: "(subscription == %@)", argumentArray: [container!]) : NSPredicate(format: "(categories contains %@)", argumentArray: [container!]),
				self.unreadOnlyFilterPredicate
			])
			$.fetchBatchSize = 20
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: !itemsAreSortedByLoadDate ? nil : "loadDate.timeIntervalSinceReferenceDate", cacheName: nil)
		$.delegate = self
		return $
	}
	private var fetchedResultsController_ : NSFetchedResultsController?
	private var fetchedResultsController: NSFetchedResultsController {
		get {
			if let $ = fetchedResultsController_ {
				return $
			}
			fetchedResultsController_ = regeneratedFetchedResultsController()
			var fetchError: NSError?
			self.fetchedResultsController.performFetch(&fetchError)
			assert(nil == fetchError)
			return fetchedResultsController_!
		}
	}
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
					self.loadError = $(streamError).$()
					self.presentErrorMessage(NSLocalizedString("Failed to load more.", comment: ""))
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
					let barrierIndexPath = NSIndexPath(forRow: $(lastVisibleIndexPath).$(0).row + numberOfItemsToPreload, inSection: lastVisibleIndexPath.section)
					let indexPathForLastLoadedItem = self.fetchedResultsController.indexPathForObject(lastLoadedItem)!
					return $($(indexPathForLastLoadedItem).$(0).compare($(barrierIndexPath).$(0)) == .OrderedAscending).$(0)
				}
				else {
					return true
				}
			}
			return false
		}()
		if $(shouldLoadMore).$(0) {
			self.loadMore { loadDateDidChange in
			}
		}
		else if (loadCompleted) {
			tableView.tableFooterView = nil
		}
	}
	@IBAction private func selectUnread(sender: AnyObject!) {
		self.showUnreadOnly = true
		self.toolbarItems = regeneratedToolbarItems()
	}
	@IBAction private func unselectUnread(sender: AnyObject!) {
		self.showUnreadOnly = false
		self.toolbarItems = regeneratedToolbarItems()
	}
	@IBAction private func refresh(sender: AnyObject!) {
		let refreshControl = self.refreshControl!
		if loadInProgress && $(nil == continuation).$() {
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
			$(error).$()
			dispatch_async(dispatch_get_main_queue()) {
				self.presentErrorMessage(NSLocalizedString("Failed to mark all as read.", comment: ""))
			}
		}
	}
	@IBAction private func action(sender: AnyObject?) {
		let activityViewController = UIActivityViewController(activityItems: [container!], applicationActivities: applicationActivities)
		self.navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
	}
	// MARK: -
	private func itemForIndexPath(indexPath: NSIndexPath!) -> Item! {
		if nil != indexPath {
			return self.fetchedResultsController.objectAtIndexPath(indexPath) as! Item
		}
		else {
			return nil
		}
	}
	private var selectedItem: Item {
		return self.itemForIndexPath(self.tableView.indexPathForSelectedRow()!)
	}
	// MARK: -
	private func configureCell(rawCell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let cell = rawCell as! ItemTableViewCell
		let item = fetchedResultsController.objectAtIndexPath($(indexPath).$(0)) as! Item
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
		(fetchResultsAreAnimated ? invoke : UIView.performWithoutAnimation) {
			self.tableView.beginUpdates()
		}
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
		$(stringFromFetchedResultsChangeType(type)).$()
		switch type {
		case .Insert:
			$(tableView.numberOfRowsInSection($(newIndexPath!).$().section)).$()
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
		case .Delete:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
		case .Update:
			$(tableView.numberOfRowsInSection($(indexPath!).$().section)).$()
			if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
				self.configureCell(cell, atIndexPath: indexPath!)
			}
		case .Move:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
		}
	}
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		(fetchResultsAreAnimated ? invoke : UIView.performWithoutAnimation) {
			self.tableView.endUpdates()
		}
	}
	// MARK: -
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		let numberOfSections = fetchedResultsController.sections?.count ?? 0
		return $(numberOfSections).$(0)
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let numberOfRows = (fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo).numberOfObjects
		return $(numberOfRows).$(0)
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let loadDate: NSDate? = {
			if itemsAreSortedByLoadDate {
				let sectionName = (self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo).name!
				return Optional(NSDate(timeIntervalSinceReferenceDate: (sectionName as NSString).doubleValue))
			}
			else {
				return self.loadDate
			}
		}()
		if loadDate == self.loadDate {
			return nil
		}
		let title: String = {
			if let loadDate = loadDate {
				let loadAgo = loadAgoLongDateComponentsFormatter.stringFromDate(loadDate, toDate: self.nowDate)
				return NSLocalizedString("\(loadAgo!) ago", comment: "")
			}
			else {
				return NSLocalizedString("Just now", comment: "")
			}
		}()
		return _0 ? nil : title
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Item", forIndexPath: indexPath) as! UITableViewCell
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.ShowListPages, sender: self)
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
		case MainStoryboard.SegueIdentifiers.ShowListPages:
			let pageViewController = segue.destinationViewController as! UIPageViewController
			let itemsPageViewControllerDataSource: ItemsPageViewControllerDataSource = {
				let $ = pageViewController.dataSource as! ItemsPageViewControllerDataSource
				$.items = self.fetchedResultsController.fetchedObjects! as! [Item]
				return $
			}()
			let initialViewController = itemsPageViewControllerDataSource.viewControllerForItem(self.selectedItem, storyboard: pageViewController.storyboard!)
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
			nowDate = NSDate()
		}
	}
	// MARK: -
    func modelIdentifierForElementAtIndexPath(indexPath: NSIndexPath, inView view: UIView) -> String {
		if let item = self.itemForIndexPath(indexPath) {
			return item.objectID.URIRepresentation().absoluteString!
		}
		else {
			let invalidModelIdentifier = ""
			return $(invalidModelIdentifier).$()
		}
	}
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
		let objectIDURL = NSURL(string: identifier)!
		let managedObjectContext = fetchedResultsController.managedObjectContext
		let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIDURL)!
		let object = managedObjectContext.objectWithID(objectID)
		let indexPath = fetchedResultsController.indexPathForObject(object)!
		return $(indexPath).$()
	}
	// MARK: -
	private var blocksDelayedTillViewWillAppear = [Handler]()
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		nowDate = NSDate()
		for i in blocksDelayedTillViewWillAppear {
			i()
		}
		blocksDelayedTillViewWillAppear = []
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(animated: Bool) {
		let loadDateLabel = self.statusLabel
		let binding = KVOBinding(object: self, keyPath: "loadDate", options: .New | .Initial) { change in
			let loadDate = change[NSKeyValueChangeNewKey] as! NSDate
			$(self.toolbarItems).$()
			let loadAgo = loadAgoDateComponentsFormatter.stringFromDate(loadDate, toDate: NSDate())
			self.presentInfoMessage(NSLocalizedString("Updated \(loadAgo!) ago", comment: ""))
 		}
		blocksDelayedTillViewDidDisappear += [{
			void(binding)
		}]
		super.viewDidAppear(animated)
	}
	private var blocksDelayedTillViewDidDisappear = [Handler]()
	override func viewDidDisappear(animated: Bool) {
		for i in blocksDelayedTillViewDidDisappear {
			i()
		}
		blocksDelayedTillViewDidDisappear = []
		super.viewDidDisappear(animated)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		let cellNib = UINib(nibName: "ItemTableViewCell", bundle: nil)
		tableView.registerNib(cellNib, forCellReuseIdentifier: "Item")
		blocksDelayedTillViewWillAppear += [{ [unowned self] in
			self.title = (self.container as! Titled).visibleTitle
			let tableView = self.tableView
			if let tableHeaderView = tableView.tableHeaderView {
				if tableView.contentOffset.y == 0 {
					tableView.contentOffset = CGPoint(x: 0, y: CGRectGetHeight(tableHeaderView.frame))
				}
			}
		}]
		self.tableFooterView = tableView.tableFooterView
		for item in [unfilterUnreadBarButtonItem, filterUnreadBarButtonItem] {
			if let customView = item.customView {
				customView.layoutIfNeeded()
				customView.sizeToFit()
				let button = customView.subviews.first as! UIButton
				customView.bounds = {
					var $ = customView.bounds
					$.size.width = button.bounds.width
					return $
				}()
				button.frame.origin.x = 0
				item.width = customView.bounds.width
			}
		}
		self.loadedToolbarItems = self.toolbarItems as! [UIBarButtonItem]
		self.toolbarItems = regeneratedToolbarItems()
	}
}

extension ItemsListViewController {
	func presentMessage(text: String) {
		statusLabel.text = text
		statusLabel.sizeToFit()
		statusLabel.superview!.frame.size.width = statusLabel.bounds.width
		statusBarButtonItem.width = $(statusLabel.superview!.bounds.width).$()
	}
	override func presentErrorMessage(text: String) {
		presentMessage(text)
	}
	override func presentInfoMessage(text: String) {
		presentMessage(text)
	}
}

