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
		let timeInterval = date.timeIntervalSinceDate(date)
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
		return container!.viewStates
	}
#endif
	dynamic var containerViewState: RSSReaderData.ContainerViewState? {
		get {
			let containerViewState = (containerViewStates.filter { $0.containerViewPredicate.isEqual(containerViewPredicate) }).onlyElement
			return containerViewState
		}
		set {
			assert(containerViewState == nil)
			let newViewState = newValue!
			newViewState.container = container
			newViewState.containerViewPredicate = containerViewPredicate
	#if true
			containerViewStates += [newViewState]
	#endif
			assert(containerViewStates.contains(newViewState))
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
		return defaults.numberOfItemsToLoadPastVisible
	}
	var numberOfItemsToLoadInitially: Int {
		return defaults.numberOfItemsToLoadInitially
	}
	var numberOfItemsToLoadLater: Int {
		return defaults.numberOfItemsToLoadLater
	}
	private func proceedWithStreamContentsResult(stateBefore: (ongoingLoadDate: NSDate, continuation: String?), newContinuation: String?, items: [Item]!, streamError: ErrorType?, completionHandler: (loadDateDidChange: Bool) -> Void) {
		guard stateBefore.ongoingLoadDate == $(ongoingLoadDate) else {
			// Ignore results from previous sessions.
			completionHandler(loadDateDidChange: true)
			return
		}
		if nil == containerViewState {
			let newContainerViewState: ContainerViewState = {
				let managedObjectContext = container!.managedObjectContext!
				assert(managedObjectContext == mainQueueManagedObjectContext)
				let newViewState = NSEntityDescription.insertNewObjectForEntityForName("ContainerViewState", inManagedObjectContext: managedObjectContext) as! RSSReaderData.ContainerViewState
				return newViewState
			}()
			containerViewState = newContainerViewState
		}
		defer {
			loadInProgress = false
			completionHandler(loadDateDidChange: false)
			loadMoreIfNecessary()
		}
		guard nil == streamError else {
			loadError = $(streamError!)
			presentErrorMessage(NSLocalizedString("Failed to load more.", comment: ""))
			return
		}
		if nil == stateBefore.continuation {
			loadDate = ongoingLoadDate
		}
		else {
			assert(loadDate == ongoingLoadDate)
		}
		if let lastItemInResultAsync = (items).last where _0 {
			let managedObjectContext = fetchedResultsController.managedObjectContext
			let lastItemInResult = managedObjectContext.sameObject(lastItemInResultAsync)
			assert(containerViewPredicate.evaluateWithObject(lastItemInResult))
			assert(lastItemInResult == lastLoadedItem)
			assert(nil != fetchedResultsController.indexPathForObject(lastItemInResult))
		}
		continuation = newContinuation
		if nil == continuation {
			loadCompleted = true
			UIView.animateWithDuration(0.4) {
				self.tableView.tableFooterView = nil
			}
		}
	}
	private func loadMore(completionHandler: (loadDateDidChange: Bool) -> Void) {
		assert(!loadInProgress)
		assert(!loadCompleted)
		assert(nil == loadError)
		let oldContinuation = continuation
		if nil == oldContinuation {
			ongoingLoadDate = NSDate()
		}
		else if nil == ongoingLoadDate {
			ongoingLoadDate = loadDate
		}
		let oldOngoingLoadDate = ongoingLoadDate!
		loadInProgress = true
		let excludedCategory: Folder? = showUnreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext) : nil
		let numberOfItemsToLoad = (oldContinuation != nil) ? numberOfItemsToLoadLater : numberOfItemsToLoadInitially
		rssSession!.streamContents(container!, excludedCategory: excludedCategory, continuation: oldContinuation, count: numberOfItemsToLoad, loadDate: $(oldOngoingLoadDate)) { newContinuation, items, streamError in
			dispatch_async(dispatch_get_main_queue()) {
				self.proceedWithStreamContentsResult((ongoingLoadDate: oldOngoingLoadDate, continuation: oldContinuation), newContinuation: newContinuation, items: items, streamError: streamError, completionHandler: completionHandler)
			}
		}
	}
	private func fetchLastLoadedItemDate(completionHandler: NSDate? -> ()) {
		guard let containerViewState = containerViewState else {
			completionHandler(nil)
			return
		}
		let containerViewStateObjectID = containerViewState.objectID
		let managedObjectContext = backgroundQueueManagedObjectContext
		managedObjectContext.performBlock {
			let containerViewState = managedObjectContext.objectWithID(containerViewStateObjectID) as! ContainerViewState
			let date = containerViewState.lastLoadedItem?.date
			completionHandler(date)
		}
	}
	private func loadMoreIfNecessaryWithLastLoadedItemDate(lastLoadedItemDate: NSDate?) {
		let shouldLoadMore: Bool = {
			guard !(loadInProgress || loadCompleted || loadError != nil) else {
				return false
			}
			if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
				if let lastLoadedItemDate = lastLoadedItemDate where 0 < indexPathsForVisibleRows.count {
					let lastVisibleIndexPath = indexPathsForVisibleRows.last!
					let numberOfRows = fetchedResultsController.sections![0].numberOfObjects
					assert(0 < numberOfRows)
					let barrierRow = min(lastVisibleIndexPath.row + numberOfItemsToLoadPastVisible, numberOfRows - 1)
					let barrierIndexPath = NSIndexPath(forRow: (barrierRow) , inSection: lastVisibleIndexPath.section)
					let barrierItem = fetchedResultsController.objectAtIndexPath(barrierIndexPath) as! Item
					return !(((lastLoadedItemDate).compare((barrierItem.date))) == .OrderedAscending)
				}
				else {
					return true
				}
			}
			return false
		}()
		if (shouldLoadMore) {
			loadMore { loadDateDidChange in
			}
		}
		else if (loadCompleted) {
			tableView.tableFooterView = nil
		}
	}
	private func loadMoreIfNecessary() {
		fetchLastLoadedItemDate { lastLoadedItemDate in
			dispatch_async(dispatch_get_main_queue()) {
				self.loadMoreIfNecessaryWithLastLoadedItemDate(lastLoadedItemDate)
			}
		}
	}
	func reloadViewForNewConfiguration() {
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
		fetchedResultsControllerDelegate = regeneratedFetchedResultsControllerDelegate()
		ongoingLoadDate = nil
		try! $(self).fetchedResultsController.performFetch()
		tableView.reloadData()
		loadMoreIfNecessary()
	}
	@IBAction private func selectUnread(sender: AnyObject!) {
		showUnreadOnly = true
		reloadViewForNewConfiguration()
	}
	@IBAction private func unselectUnread(sender: AnyObject!) {
		showUnreadOnly = false
		reloadViewForNewConfiguration()
	}
	@IBAction private func refresh(sender: AnyObject!) {
		guard let refreshControl = refreshControl else {
			fatalError()
		}
		if loadInProgress && $(nil == continuation) {
			refreshControl.endRefreshing()
		}
		else {
			loadCompleted = false
			continuation = nil
			loadInProgress = false
			loadError = nil
			refreshControl.endRefreshing()
			loadMore { loadDateDidChange in
				if !loadDateDidChange {
				}
			}
			UIView.animateWithDuration(0.4) {
				self.tableView.tableFooterView = self.tableFooterView
			}
		}
	}
	@IBAction private func markAllAsRead(sender: AnyObject!) {
		let items = (container as! ItemsOwner).ownItems
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
		navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
	}
	// MARK: -
	private func itemForIndexPath(indexPath: NSIndexPath!) -> Item! {
		if nil != indexPath {
			return fetchedResultsController.objectAtIndexPath(indexPath) as! Item
		}
		else {
			return nil
		}
	}
	private var selectedItem: Item {
		return itemForIndexPath(tableView.indexPathForSelectedRow!)
	}
	func itemDateFormatted(itemDate: NSDate) -> String {
		guard nil != NSClassFromString("NSDateComponentsFormatter") else {
			return ""
		}
		let timeInterval = nowDate.timeIntervalSinceDate(itemDate)
		return dateComponentsFormatter.stringFromTimeInterval(timeInterval)!
	}
	// MARK: -
	internal func configureCell(cell: ItemTableViewCell, atIndexPath indexPath: NSIndexPath) {
		let item = fetchedResultsController.objectAtIndexPath((indexPath)) as! Item
		defer {
			cell.itemObjectID = item.objectID
		}
		guard cell.itemObjectID != item.objectID else {
			return
		}
		if let titleLabel = cell.titleLabel {
			let text = item.title ?? (item.itemID as NSString).lastPathComponent
			if text != titleLabel.text {
				titleLabel.text = text
			}
		}
		if let sourceLabel = cell.sourceLabel {
			let text = item.subscription.title?.lowercaseString
			if text != sourceLabel.text {
				sourceLabel.text = text
			}
		}
		if let dateLabel = cell.dateLabel where defaults.showDates {
			let text = "\(itemDateFormatted(item.date))".lowercaseString
			if dateLabel.text != text {
				dateLabel.text = text
				if _0 {
				dateLabel.textColor = item.markedAsRead ? nil : UIColor.redColor()
				}
			}
		}
		if let readMarkLabel = cell.readMarkLabel where defaults.showUnreadMark {
			let alpha = CGFloat(item.markedAsRead ? 0 : 1)
			if readMarkLabel.alpha != alpha {
				readMarkLabel.alpha = alpha
			}
		}
	}
	// MARK: -
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		let numberOfSections = fetchedResultsController.sections?.count ?? 0
		return (numberOfSections)
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let t = disableTrace(); defer { t }
		let numberOfRows = $($(fetchedResultsController).sections![section].numberOfObjects)
		return $(numberOfRows)
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard defaults.itemsAreSortedByLoadDate else {
			return nil
		}
		let sectionName = fetchedResultsController.sections![section].name
		let dateForDisplay: NSDate? = NSDate(timeIntervalSinceReferenceDate: (sectionName as NSString).doubleValue)
		let title: String = {
			if let loadDate = dateForDisplay {
				let loadAgo = loadAgoLongDateComponentsFormatter.stringFromDate(loadDate, toDate: nowDate)
				return String.localizedStringWithFormat(NSLocalizedString("%@ ago", comment: ""), loadAgo!)
			}
			else {
				return NSLocalizedString("Just now", comment: "")
			}
		}()
		return _0 ? nil : title
	}
	var reusedCellGenerator: TableViewHeightBasedReusedCellGenerator<ItemsListViewController>!
	var systemLayoutSizeCachingDataSource = SystemLayoutSizeCachingTableViewCellDataSource(layoutSizeDefiningValueForCell: {guard $0.reuseIdentifier != "Item" else { return nil }; return $0.reuseIdentifier}, cellShouldBeReusedWithoutLayout: {$0.reuseIdentifier != "Item"})
	// MARK: -
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let reuseIdentifier = reusedCellGenerator?.reuseIdentifierForCellForRowAtIndexPath(indexPath) ?? "Item"
		let cell = tableView.dequeueReusableCellWithIdentifier($(reuseIdentifier), forIndexPath: indexPath) as! ItemTableViewCell
		if nil != reusedCellGenerator {
			cell.systemLayoutSizeCachingDataSource = systemLayoutSizeCachingDataSource
		}
		let dt = disableTrace(); defer { dt }
		configureCell(cell, atIndexPath: $(indexPath))
		return cell
	}
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if nil == heightSampleLabel {
			let viewWithVariableHeight = viewWithVariableHeightForCell(cell)
			heightSampleLabel = NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(viewWithVariableHeight)) as! UILabel
		}
		let rowHeight = tableView.rectForRowAtIndexPath(indexPath).height
		reusedCellGenerator?.addRowHeight(rowHeight, forCell: cell, atIndexPath: indexPath)
		rowHeightEstimator.addRowHeight(rowHeight, forIndexPath: indexPath)
	}
	var rowHeightEstimator: FrequencyAndWeightBasedTableRowHeightEstimator<ItemsListViewController>!
	override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		guard let estimatedHeight = rowHeightEstimator.estimatedRowHeightForItemAtIndexPath(indexPath) else {
			return UITableViewAutomaticDimension
		}
		return estimatedHeight
	}
	// MARK: -
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.ShowListPages, sender: self)
	}
	// MARK: -
	override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		tableView.snapHeaderToTop(animated: true)
	}
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		if nil != rssSession && nil != view.superview && !refreshControl!.refreshing {
			loadMoreIfNecessary()
		}
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowListPages:
			let pageViewController = segue.destinationViewController as! UIPageViewController
			let itemsPageViewControllerDataSource: ItemsPageViewControllerDataSource = {
				let $ = pageViewController.dataSource as! ItemsPageViewControllerDataSource
				$.items = fetchedResultsController.fetchedObjects! as! [Item]
				return $
			}()
			let initialViewController = itemsPageViewControllerDataSource.viewControllerForItem(selectedItem, storyboard: pageViewController.storyboard!)
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
		container = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.containerObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Container?
		if nil != container {
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
		loadMoreIfNecessary()
	}
	private var blocksDelayedTillViewDidDisappear = [Handler]()
	override func viewDidDisappear(animated: Bool) {
		blocksDelayedTillViewDidDisappear.forEach {$0()}
		blocksDelayedTillViewDidDisappear = []
		super.viewDidDisappear(animated)
	}
	// MARK: -
	func configureFetchedResultsController() {
		fetchedResultsControllerDelegate = regeneratedFetchedResultsControllerDelegate()
		try! $(fetchedResultsController).performFetch()
	}
	func configureTitle() {
		if nil == title {
			title = (container as! Titled).visibleTitle
		}
		if let tableHeaderView = tableView.tableHeaderView {
			if tableView.contentOffset.y == 0 {
				tableView.contentOffset = CGPoint(x: 0, y: CGRectGetHeight(tableHeaderView.frame))
			}
		}
	}
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		if defaults.cellHeightCachingEnabled {
			let reuseIdentifiersForHeightCachingCells = (0...3).map {"Item-\($0)"}
			reusedCellGenerator = TableViewHeightBasedReusedCellGenerator(dataSource: self, heightAgnosticCellReuseIdentifier: "Item", reuseIdentifiersForHeightCachingCells: reuseIdentifiersForHeightCachingCells)
			for (i, reuseIdentifier) in reuseIdentifiersForHeightCachingCells.enumerate() {
				let cellNib = UINib(nibName: "ItemTableViewCell-\(i)", bundle: nil)
				tableView.registerNib(cellNib, forCellReuseIdentifier: reuseIdentifier)
			}
		}
		rowHeightEstimator = FrequencyAndWeightBasedTableRowHeightEstimator(dataSource: self)
		blocksDelayedTillViewWillAppearOrStateRestoration += [{ [unowned self] in
			self.configureFetchedResultsController()
		}]
		let cellNib = UINib(nibName: "ItemTableViewCell", bundle: nil)
		tableView.registerNib(cellNib, forCellReuseIdentifier: "Item")
		blocksDelayedTillViewWillAppear += [{ [unowned self] in
			self.configureTitle()
		}]
		tableFooterView = tableView.tableFooterView
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
		loadedRightBarButtonItems = navigationItem.rightBarButtonItems
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
	}
	var heightSampleLabel: UILabel!
	var cachedVariableHeights: [NSManagedObjectID : CGFloat] = [:]
	// MARK: -
	deinit {
		$(self)
	}
}

extension ItemsListViewController: FrequencyAndWeightBasedTableRowHeightEstimatorDataSource {
	func weightForHeightDefiningValueAtIndexPath(indexPath: NSIndexPath) -> Int {
		let item = fetchedResultsController.objectAtIndexPath(indexPath) as! Item
		let length = item.title.utf16.count
		return length
	}
}

extension ItemsListViewController: TableViewHeightBasedReusedCellGeneratorDataSource {
	func viewWithVariableHeightForCell(cell: UITableViewCell) -> UIView {
		let cell = cell as! ItemTableViewCell
		return cell.titleLabel
	}
	func variableHeightForCell(cell: UITableViewCell) -> CGFloat {
		return viewWithVariableHeightForCell(cell).bounds.height
	}
	func isReadyForMeasuringHeigthsForData() -> Bool {
		return nil != heightSampleLabel
	}
	func variableHeightForDataAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
		let item = fetchedResultsController.objectAtIndexPath(indexPath) as! Item
		let cacheKey = item.objectID
		if let cachedHeight = cachedVariableHeights[cacheKey] {
			return cachedHeight
		}
		heightSampleLabel.text = item.title
		let size = heightSampleLabel.sizeThatFits(CGSize(width: heightSampleLabel.bounds.width, height: CGFloat.max))
		let height = size.height
		cachedVariableHeights[cacheKey] = height
		return height
	}
}

extension ItemsListViewController {
	func regeneratedFetchedResultsControllerDelegate() -> TableViewFetchedResultsControllerDelegate {
		let fetchRequest: NSFetchRequest = {
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
				containerViewPredicate
			])
#if false
			$.relationshipKeyPathsForPrefetching = [E••{$0.categories}]
#endif
			$.returnsObjectsAsFaults = false
			$.fetchBatchSize = defaults.fetchBatchSize
			return $
		}()
		let itemLoadDateTimeIntervalSinceReferenceDateKeyPath = Item.self••{$0.loadDate.timeIntervalSinceReferenceDate}
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainQueueManagedObjectContext, sectionNameKeyPath: !defaults.itemsAreSortedByLoadDate ? nil : itemLoadDateTimeIntervalSinceReferenceDateKeyPath, cacheName: nil)
		let configureCell = { [unowned self] (cell: UITableViewCell, indexPath: NSIndexPath) -> Void in
			self.configureCell(cell as! ItemTableViewCell, atIndexPath: indexPath)
		}
		let $ = TableViewFetchedResultsControllerDelegate(tableView: tableView, fetchedResultsController: fetchedResultsController, updateCell: configureCell)
		fetchedResultsController.delegate = $
		return $
	}
}

// MARK: - UIDataSourceModelAssociation
extension ItemsListViewController: UIDataSourceModelAssociation {
    func modelIdentifierForElementAtIndexPath(indexPath: NSIndexPath, inView view: UIView) -> String? {
		if let item = itemForIndexPath(indexPath) {
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
