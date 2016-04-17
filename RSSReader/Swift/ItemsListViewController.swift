//
//  ItemsListViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import GEKeyPaths
import UIKit
import CoreData

extension Item {
	class func keyPathsForValuesAffectingItemListSectionName() -> Set<String> {
		return [self••{$0.date}, self••{$0.loadDate}]
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

let loadAgoDateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Full
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.allowedUnits = [.Minute, .Year, .Month, .WeekOfMonth, .Day, .Hour]
	return $;
}()
private let loadAgoLongDateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Full
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.includesApproximationPhrase = true
	$.allowedUnits = [.Minute, .Year, .Month, .WeekOfMonth, .Day, .Hour]
	return $;
}()

private var fetchResultsAreAnimated: Bool {
	return defaults.fetchResultsAreAnimated
}

class ItemsListViewController: UITableViewController {
	static let Self_ = ItemsListViewController.self
	final var container: Container?
	final var multipleSourcesEnabled = false
	var showUnreadEnabled = true
	class var keyPathsForValuesAffectingContainerViewState: Set<String> {
		return [Self_••{$0.containerViewPredicate}]
	}
#if true
	lazy var containerViewStates: [RSSReaderData.ContainerViewState] = {
		return Array(self.container!.viewStates)
	}()
#else
	var containerViewStates: Set<RSSReaderData.ContainerViewState> {
		return self.container!.viewStates
	}
#endif
	dynamic var containerViewState: RSSReaderData.ContainerViewState? {
		get {
			let containerViewPredicate = self.containerViewPredicate
			let containerViewState = (self.containerViewStates.filter { $0.containerViewPredicate.isEqual(containerViewPredicate) }).onlyElement
			return containerViewState
		}
		set {
			assert(self.containerViewState == nil)
			let newViewState = newValue!
			newViewState.container = container
			newViewState.containerViewPredicate = containerViewPredicate
	#if true
			containerViewStates += [newViewState]
	#endif
			assert(self.containerViewStates.contains(newViewState))
		}
	}
	private var ongoingLoadDate: NSDate?
	private var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState?.continuation }
	}
	class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [Self_••{$0.containerViewState!.loadDate}]
	}
	private dynamic var loadDate: NSDate? {
		set { containerViewState!.loadDate = newValue! }
		get { return containerViewState?.loadDate }
	}
	private var lastLoadedItem: Item? {
		return containerViewState?.lastLoadedItem
	}
	private var loadCompleted: Bool {
		set { containerViewState!.loadCompleted = newValue }
		get { return containerViewState?.loadCompleted ?? false }
	}
	private var loadError: ErrorType? {
		set { containerViewState!.loadError = newValue }
		get { return containerViewState?.loadError }
	}
	//
	private var loadInProgress = false
	private var nowDate: NSDate!
	private var tableFooterView: UIView?
	private var indexPathForTappedAccessoryButton: NSIndexPath?
	// MARK: -
	private var loadedRightBarButtonItems: [UIBarButtonItem]!
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var statusBarButtonItem: UIBarButtonItem!
	@IBOutlet private var filterUnreadBarButtonItem: UIBarButtonItem!
	@IBOutlet private var unfilterUnreadBarButtonItem: UIBarButtonItem!
	private dynamic var showUnreadOnly = false
	private func regeneratedRightBarButtonItems() -> [UIBarButtonItem] {
		let excludedItems = showUnreadEnabled ? [(showUnreadOnly ?  filterUnreadBarButtonItem : unfilterUnreadBarButtonItem)!] : [filterUnreadBarButtonItem!, unfilterUnreadBarButtonItem!]
		let $ = loadedRightBarButtonItems.filter { nil == excludedItems.indexOf($0) }
		return $
	}
	class var keyPathsForValuesAffectingContainerViewPredicate: Set<String> {
		return [Self_.self••{$0.showUnreadOnly}]
	}
	private var containerViewPredicate: NSPredicate {
		if showUnreadOnly {
			return NSPredicate(format: "SUBQUERY(\(Item.self••{$0.categories}), $x, $x.\(Folder.self••{$0.streamID}) ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}
	// MARK: -
	internal var fetchedResultsControllerDelegate : TableViewFetchedResultsControllerDelegate!
	var fetchedResultsController: NSFetchedResultsController {
		return fetchedResultsControllerDelegate.fetchedResultsController
	}
	// MARK: -
	var numberOfItemsToLoadPastVisible: Int {
		return 10
	}
	var numberOfItemsToLoadInitially: Int {
		return numberOfItemsToLoadPastVisible * 2
	}
	var numberOfItemsToLoadLater: Int {
		return numberOfItemsToLoadPastVisible * 5
	}
	private func loadMore(completionHandler: (loadDateDidChange: Bool) -> Void) {
		assert(!loadInProgress)
		assert(!loadCompleted)
		assert(nil == loadError)
		let originalContinuation = self.continuation
		if nil == originalContinuation {
			self.ongoingLoadDate = NSDate()
		}
		else if nil == self.ongoingLoadDate {
			self.ongoingLoadDate = self.loadDate
		}
		let ongoingLoadDate = self.ongoingLoadDate!
		loadInProgress = true
		let excludedCategory: Folder? = showUnreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext) : nil
		let numberOfItemsToLoad = (self.continuation != nil) ? self.numberOfItemsToLoadLater : self.numberOfItemsToLoadInitially
		rssSession!.streamContents(container!, excludedCategory: excludedCategory, continuation: self.continuation, count: numberOfItemsToLoad, loadDate: $(ongoingLoadDate)) { continuation, items, streamError in
			dispatch_async(dispatch_get_main_queue()) {
				if ongoingLoadDate != $(self.ongoingLoadDate) {
					// Ignore results from previous sessions.
					completionHandler(loadDateDidChange: true)
					return
				}
				if nil == self.containerViewState {
					let containerViewState: ContainerViewState = {
						let managedObjectContext = self.container!.managedObjectContext!
						assert(managedObjectContext == mainQueueManagedObjectContext)
						let newViewState = NSEntityDescription.insertNewObjectForEntityForName("ContainerViewState", inManagedObjectContext: managedObjectContext) as! RSSReaderData.ContainerViewState
						return newViewState
					}()
					self.containerViewState = containerViewState
				}
				if let streamError = streamError {
					self.loadError = $(streamError)
					self.presentErrorMessage(NSLocalizedString("Failed to load more.", comment: ""))
				}
				else {
					if nil == originalContinuation {
						self.loadDate = ongoingLoadDate
					}
					else {
 						assert(self.loadDate == ongoingLoadDate)
					}
					if let lastItemInCompletion = (items).last {
						let managedObjectContext = self.fetchedResultsController.managedObjectContext
						let lastLoadedItem = managedObjectContext.sameObject(lastItemInCompletion)
						assert(self.containerViewPredicate.evaluateWithObject(lastLoadedItem))
						assert(self.lastLoadedItem == lastLoadedItem)
						assert(nil != self.fetchedResultsController.indexPathForObject(lastLoadedItem))
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
			if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
				if let lastLoadedItem = self.lastLoadedItem where 0 < indexPathsForVisibleRows.count {
					let lastVisibleIndexPath = indexPathsForVisibleRows.last!
					let numberOfRows = fetchedResultsController.fetchedObjects!.count
					assert(0 < numberOfRows)
					let barrierRow = min(lastVisibleIndexPath.row + self.numberOfItemsToLoadPastVisible, numberOfRows - 1)
					let barrierIndexPath = NSIndexPath(forRow: (barrierRow) , inSection: lastVisibleIndexPath.section)
					let barrierItem = self.fetchedResultsController.objectAtIndexPath(barrierIndexPath) as! Item
					return !(((lastLoadedItem.date).compare((barrierItem.date))) == .OrderedAscending)
				}
				else {
					return true
				}
			}
			return false
		}()
		if (shouldLoadMore) {
			self.loadMore { loadDateDidChange in
			}
		}
		else if (loadCompleted) {
			tableView.tableFooterView = nil
		}
	}
	func reloadViewForNewConfiguration() {
		self.navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
		self.fetchedResultsControllerDelegate = self.regeneratedFetchedResultsControllerDelegate()
		self.ongoingLoadDate = nil
		try! $(self).fetchedResultsController.performFetch()
		self.tableView.reloadData()
		self.loadMoreIfNecessary()
	}
	@IBAction private func selectUnread(sender: AnyObject!) {
		self.showUnreadOnly = true
		self.reloadViewForNewConfiguration()
	}
	@IBAction private func unselectUnread(sender: AnyObject!) {
		self.showUnreadOnly = false
		self.reloadViewForNewConfiguration()
	}
	@IBAction private func refresh(sender: AnyObject!) {
		let refreshControl = self.refreshControl!
		if loadInProgress && $(nil == continuation) {
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
			$(error)
			dispatch_async(dispatch_get_main_queue()) {
				if nil != error {
					self.presentErrorMessage(NSLocalizedString("Failed to mark all as read.", comment: ""))
				}
				else {
					self.presentInfoMessage(NSLocalizedString("Marked all as read.", comment: ""))
				}
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
		return self.itemForIndexPath(self.tableView.indexPathForSelectedRow!)
	}
	// MARK: -
	internal func configureCell(rawCell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let cell = rawCell as! ItemTableViewCell
		let item = fetchedResultsController.objectAtIndexPath((indexPath)) as! Item
		if let titleLabel = cell.titleLabel {
			titleLabel.text = item.title ?? (item.itemID as NSString).lastPathComponent
		}
		if let sourceLabel = cell.sourceLabel {
			sourceLabel.text = item.subscription.title
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
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		let numberOfSections = fetchedResultsController.sections?.count ?? 0
		return (numberOfSections)
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let numberOfRows = fetchedResultsController.sections![section].numberOfObjects
		return $(numberOfRows)
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let loadDate: NSDate? = {
			if defaults.itemsAreSortedByLoadDate {
				let sectionName = self.fetchedResultsController.sections![section].name
				return NSDate(timeIntervalSinceReferenceDate: (sectionName as NSString).doubleValue)
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
				return String.localizedStringWithFormat(NSLocalizedString("%@ ago", comment: ""), loadAgo!)
			}
			else {
				return NSLocalizedString("Just now", comment: "")
			}
		}()
		return _0 ? nil : title
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Item", forIndexPath: indexPath)
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
		if nil != rssSession && nil != self.view.superview {
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
	private var blocksDelayedTillViewWillAppearOrStateRestoration = [Handler]()
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
		self.container = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.containerObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Container?
		if nil != self.container {
			nowDate = NSDate()
		}
		blocksDelayedTillViewWillAppearOrStateRestoration.forEach {$0()}
		blocksDelayedTillViewWillAppearOrStateRestoration = []
	}
	// MARK: -
	private var blocksDelayedTillViewWillAppear = [Handler]()
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		(self)
		nowDate = NSDate()
		let binding = KVOBinding(self•{$0.loadDate}, options: [.New, .Initial]) { change in
			(•self.toolbarItems!)
			let newValue = change![NSKeyValueChangeNewKey]
			if let loadDate = nilForNull(newValue!) as! NSDate? {
				let loadAgo = loadAgoDateComponentsFormatter.stringFromDate(loadDate, toDate: NSDate())
				self.presentInfoMessage(String.localizedStringWithFormat(NSLocalizedString("Updated %@ ago", comment: ""), loadAgo!))
			}
			else {
				self.presentInfoMessage(NSLocalizedString("Not updated before", comment: ""))
			}
 		}
		blocksDelayedTillViewWillAppearOrStateRestoration.forEach {$0()}
		blocksDelayedTillViewWillAppearOrStateRestoration = []
		blocksDelayedTillViewWillAppear.forEach {$0()}
		blocksDelayedTillViewWillAppear = []
		blocksDelayedTillViewDidDisappear += [{
			void(binding)
		}]
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(animated: Bool) {
		$(self)
		super.viewDidAppear(animated)
		self.loadMoreIfNecessary()
	}
	private var blocksDelayedTillViewDidDisappear = [Handler]()
	override func viewDidDisappear(animated: Bool) {
		blocksDelayedTillViewDidDisappear.forEach {$0()}
		blocksDelayedTillViewDidDisappear = []
		super.viewDidDisappear(animated)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		blocksDelayedTillViewWillAppearOrStateRestoration += [{ [unowned self] in
			self.fetchedResultsControllerDelegate = self.regeneratedFetchedResultsControllerDelegate()
			try! $(self.fetchedResultsController).performFetch()
		}]
		let cellNib = UINib(nibName: self.multipleSourcesEnabled ? "MultisourceItemTableViewCell" : "ItemTableViewCell", bundle: nil)
		tableView.registerNib(cellNib, forCellReuseIdentifier: "Item")
		blocksDelayedTillViewWillAppear += [{ [unowned self] in
			self.title = self.title ?? (self.container as! Titled).visibleTitle
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
		self.loadedRightBarButtonItems = self.navigationItem.rightBarButtonItems
		self.navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
	}
	// MARK: -
	deinit {
		$(self)
	}
}

extension ItemsListViewController {
	func regeneratedFetchedResultsControllerDelegate() -> TableViewFetchedResultsControllerDelegate {
		let fetchRequest: NSFetchRequest = {
			let container = self.container
			let E = Item.self
			let $ = NSFetchRequest(entityName: E.entityName())
			$.sortDescriptors =	sortDescriptorsForContainers
			$.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[
				{
					if container! is Subscription {
						return NSPredicate(format: "(\(E••{$0.subscription}) == %@)", argumentArray: [container!])
					}
					else {
						return NSPredicate(format: "(\(E••{$0.categories}) CONTAINS %@)", argumentArray: [container!])
					}
				}(),
				self.containerViewPredicate
			])
			$.fetchBatchSize = 20
			return $
		}()
		let itemLoadDateTimeIntervalSinceReferenceDateKeyPath = Item.self••{$0.loadDate.timeIntervalSinceReferenceDate}
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainQueueManagedObjectContext, sectionNameKeyPath: !defaults.itemsAreSortedByLoadDate ? nil : itemLoadDateTimeIntervalSinceReferenceDateKeyPath, cacheName: nil)
		let configureCell = { [unowned self] (cell: UITableViewCell, indexPath: NSIndexPath) -> Void in
			self.configureCell(cell, atIndexPath: indexPath)
		}
		let $ = TableViewFetchedResultsControllerDelegate(tableView: tableView, fetchedResultsController: fetchedResultsController, configureCell: configureCell)
		fetchedResultsController.delegate = $
		return $
	}
}

// MARK: - UIDataSourceModelAssociation
extension ItemsListViewController: UIDataSourceModelAssociation {
    func modelIdentifierForElementAtIndexPath(indexPath: NSIndexPath, inView view: UIView) -> String? {
		if let item = self.itemForIndexPath(indexPath) {
			return item.objectID.URIRepresentation().absoluteString
		}
		else {
			let invalidModelIdentifier = ""
			return $(invalidModelIdentifier)
		}
	}
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
		let objectIDURL = NSURL(string: identifier)!
		let managedObjectContext = fetchedResultsController.managedObjectContext
		assert(managedObjectContext == mainQueueManagedObjectContext)
		let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectIDURL)!
		let object = managedObjectContext.objectWithID(objectID)
		let indexPath = fetchedResultsController.indexPathForObject(object)!
		return $(indexPath)
	}
}

extension ItemsListViewController {
	func presentMessage(text: String) {
		statusLabel.text = text
		statusLabel.sizeToFit()
		statusLabel.superview!.frame.size.width = statusLabel.bounds.width
		statusBarButtonItem.width = (statusLabel.superview!.bounds.width)
	}
	override func presentErrorMessage(text: String) {
		presentMessage(text)
	}
	override func presentInfoMessage(text: String) {
		presentMessage(text)
	}
}

