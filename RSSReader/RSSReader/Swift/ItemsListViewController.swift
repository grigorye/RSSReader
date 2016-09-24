//
//  ItemsListViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import PromiseKit
import GEBase
import UIKit
import CoreData

extension Item {
	class func keyPathsForValuesAffectingItemListSectionName() -> Set<String> {
		return [#keyPath(date), #keyPath(loadDate)]
	}
	func itemsListSectionName() -> String {
		let timeInterval = date.timeIntervalSince(date)
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
	func itemListFormattedDate(forNowDate nowDate: Date) -> String {
		let timeInterval = nowDate.timeIntervalSince(self.date)
		return dateComponentsFormatter.string(from: timeInterval)!
	}
}

class ItemsListViewController: ContainerTableViewController {
	typealias _Self = ItemsListViewController
	final var multipleSourcesEnabled = false
	var showUnreadEnabled = true
	class var keyPathsForValuesAffectingContainerViewState: Set<String> {
		return [
			#keyPath(container.viewStates),
			#keyPath(containerViewPredicate)
		]
	}
	var containerViewStateRetained: RSSReaderData.ContainerViewState?
	dynamic var containerViewState: RSSReaderData.ContainerViewState? {
		let containerViewState = (container!.viewStates.filter { $0.containerViewPredicate.isEqual(containerViewPredicate) }).onlyElement
		self.containerViewStateRetained = containerViewState
		return (containerViewState)
	}
	private var ongoingLoadDate: Date?
	private var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState?.continuation }
	}
	class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [#keyPath(containerViewState.loadDate)]
	}
	private dynamic var loadDate: Date? {
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
	private var loadError: Error? {
		set { containerViewState!.loadError = newValue }
		get { return containerViewState?.loadError }
	}
	//
	private var loadInProgress = false
	private var nowDate: Date!
	private var tableFooterView: UIView?
	private var indexPathForTappedAccessoryButton: IndexPath?
	// MARK: -
	private var loadedRightBarButtonItems: [UIBarButtonItem]!
	@IBOutlet var statusLabel: UILabel!
	@IBOutlet var statusBarButtonItem: UIBarButtonItem!
	@IBOutlet private var filterUnreadBarButtonItem: UIBarButtonItem!
	@IBOutlet private var unfilterUnreadBarButtonItem: UIBarButtonItem!
	private dynamic var showUnreadOnly = false
	private func regeneratedRightBarButtonItems() -> [UIBarButtonItem] {
		let excludedItems = showUnreadEnabled ? [(showUnreadOnly ?  filterUnreadBarButtonItem : unfilterUnreadBarButtonItem)!] : [filterUnreadBarButtonItem!, unfilterUnreadBarButtonItem!]
		let $ = loadedRightBarButtonItems.filter { nil == excludedItems.index(of: $0) }
		return $
	}
	class var keyPathsForValuesAffectingContainerViewPredicate: Set<String> {
		return [#keyPath(showUnreadOnly)]
	}
	@objc var containerViewPredicate: NSPredicate {
		if showUnreadOnly {
			return NSPredicate(format: "SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}
	// MARK: -
	class var keyPathsForValuesAffectingPredicateForItems: Set<String> {
		return [#keyPath(fetchedResultsController)]
	}
	override dynamic var predicateForItems: NSPredicate {
		return fetchedResultsController.fetchRequest.predicate!
	}
	// MARK: -
	internal var fetchedResultsControllerDelegate : TableViewFetchedResultsControllerDelegate<Item>!
	var fetchedResultsControllerDelegateAOKey: Void?
	var fetchedResultsController: NSFetchedResultsController<Item>!
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
	private func loadMore(_ completionHandler: (Bool) -> Void) {
		assert(!loadInProgress)
		assert(!loadCompleted)
		assert(nil == loadError)
		let oldContinuation = self.continuation
		if nil == oldContinuation {
			ongoingLoadDate = Date()
		}
		else if nil == ongoingLoadDate {
			ongoingLoadDate = loadDate
		}
		let oldOngoingLoadDate = ongoingLoadDate!
		loadInProgress = true
		let excludedCategory: Folder? = showUnreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext) : nil
		let numberOfItemsToLoad = (oldContinuation != nil) ? numberOfItemsToLoadLater : numberOfItemsToLoadInitially
		let containerViewStateObjectID = typedObjectID(for: containerViewState)
		let containerObjectID = typedObjectID(for: container)!
		let containerViewPredicate = self.containerViewPredicate
		firstly {
			rssSession!.streamContents(container!, excludedCategory: excludedCategory, continuation: oldContinuation, count: numberOfItemsToLoad, loadDate: $(oldOngoingLoadDate))
		}.then(on: zalgo) { streamContentsResult -> String? in
			let ongoingLoadDate = $(self.ongoingLoadDate)
			guard oldOngoingLoadDate == ongoingLoadDate else {
				throw NSError.cancelledError()
			}
			let managedObjectContext = streamContentsResult.0
			let containerViewState = containerViewStateObjectID?.object(in: managedObjectContext) ?? {
				return (NSEntityDescription.insertNewObject(forEntityName: "ContainerViewState", into: managedObjectContext) as! RSSReaderData.ContainerViewState) … {
					let container = containerObjectID.object(in: managedObjectContext)
					$0.container = container
					$0.containerViewPredicate = containerViewPredicate
				}
			}()
			if nil == oldContinuation {
				containerViewState.loadDate = ongoingLoadDate
			}
			else {
				assert(containerViewState.loadDate == ongoingLoadDate)
			}
			let items = streamContentsResult.1.items
			let lastLoadedItem = items.last
			let continuation = streamContentsResult.1.continuation
			containerViewState … {
				$0.continuation = continuation
				$0.lastLoadedItem = lastLoadedItem
			}
			if let lastLoadedItem = lastLoadedItem {
				assert(containerViewPredicate.evaluate(with: lastLoadedItem))
			}
			try managedObjectContext.save()
			return continuation
		}.then { continuation -> Void in
			if let lastLoadedItem = self.lastLoadedItem {
				assert(nil != self.fetchedResultsController.indexPath(forObject: lastLoadedItem))
			}
			if nil == continuation {
				self.loadCompleted = true
				UIView.animate(withDuration: 0.4) {
					self.tableView.tableFooterView = nil
				}
			}
		}.always { () -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			self.loadInProgress = false
			self.loadMoreIfNecessary()
		}.catch { error -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			self.presentErrorMessage(
				String.localizedStringWithFormat(
					"%@ %@",
					NSLocalizedString("Failed to load more.", comment: ""),
					(error as NSError).localizedDescription
				)
			)
		}
	}
	private func shouldLoadMore(for lastLoadedItemDate: Date?) -> Bool {
		guard !(loadInProgress || loadCompleted || loadError != nil) else {
			return false
		}
		guard let lastLoadedItemDate = lastLoadedItemDate else {
			return true
		}
		guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else {
			return false
		}
		guard 0 < indexPathsForVisibleRows.count else {
			return true
		}
		let lastVisibleIndexPath = indexPathsForVisibleRows.last!
		let numberOfRows = fetchedResultsController.sections![0].numberOfObjects
		assert(0 < numberOfRows)
		let barrierRow = min(lastVisibleIndexPath.row + numberOfItemsToLoadPastVisible, numberOfRows - 1)
		let barrierIndexPath = IndexPath(item: barrierRow, section: lastVisibleIndexPath.section)
		let barrierItem = fetchedResultsController.object(at: barrierIndexPath) 
		return !(((lastLoadedItemDate).compare((barrierItem.date))) == .orderedAscending)
	}
	private func loadMoreIfNecessary(for lastLoadedItemDate: Date?) {
		guard shouldLoadMore(for: lastLoadedItemDate) else {
			if (loadCompleted) {
				tableView.tableFooterView = nil
			}
			return
		}
		loadMore { _ in
		}
	}
	private func loadMoreIfNecessary() {
		self.loadMoreIfNecessary(for: self.lastLoadedItem?.date)
	}
	func reloadViewForNewConfiguration() {
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
		fetchedResultsController = regeneratedFetchedResultsController()
		ongoingLoadDate = nil
		try! $(self).fetchedResultsController.performFetch()
		tableView.reloadData()
		loadMoreIfNecessary()
	}
	@IBAction private func selectUnread(_ sender: AnyObject!) {
		showUnreadOnly = true
		reloadViewForNewConfiguration()
	}
	@IBAction private func unselectUnread(_ sender: AnyObject!) {
		showUnreadOnly = false
		reloadViewForNewConfiguration()
	}
	@IBAction private func refresh(_ sender: AnyObject!) {
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
			UIView.animate(withDuration: 0.4) {
				self.tableView.tableFooterView = self.tableFooterView
			}
		}
	}
	@IBAction private func markAllAsRead(_ sender: AnyObject!) {
		let items = (container as! ItemsOwner).ownItems
		for i in items {
			i.markedAsRead = true
		}
		firstly {
			rssSession!.markAllAsRead(container!)
		}.then {
			self.presentInfoMessage(NSLocalizedString("Marked all as read.", comment: ""))
		}.catch { error in
			self.presentErrorMessage(
				String.localizedStringWithFormat(
					NSLocalizedString("Failed to mark all as read. %@", comment: ""),
					"\(error)"
				)
			)
		}
	}
	@IBAction private func action(_ sender: AnyObject?) {
		let activityViewController = UIActivityViewController(activityItems: [container!], applicationActivities: applicationActivities)
		navigationController?.present(activityViewController, animated: true, completion: nil)
	}
	// MARK: -
	func itemForIndexPath(_ indexPath: IndexPath!) -> Item! {
		if nil != indexPath {
			return fetchedResultsController.object(at: indexPath) 
		}
		else {
			return nil
		}
	}
	private var selectedItem: Item {
		return itemForIndexPath(tableView.indexPathForSelectedRow!)
	}
	// MARK: -
	internal func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
		let item = fetchedResultsController.object(at: (indexPath))
		let cellDataBinder = cell as! ItemTableViewCellDataBinder
		cellDataBinder.setData((item: item, container: self.container, nowDate: nowDate))
	}
	// MARK: -
	override func numberOfSections(in tableView: UITableView) -> Int {
		let numberOfSections = fetchedResultsController.sections?.count ?? 0
		return (numberOfSections)
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let dt = disableTrace(); defer { _ = dt }
		let numberOfRows = $($(fetchedResultsController).sections![section].numberOfObjects)
		return $(numberOfRows)
	}
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard defaults.itemsAreSortedByLoadDate else {
			return nil
		}
		let sectionName = fetchedResultsController.sections![section].name
		let dateForDisplay: Date? = Date(timeIntervalSinceReferenceDate: (sectionName as NSString).doubleValue)
		let title: String = {
			if let loadDate = dateForDisplay {
				let loadAgo = loadAgoLongDateComponentsFormatter.string(from: loadDate, to: nowDate)
				return String.localizedStringWithFormat(NSLocalizedString("%@ ago", comment: ""), loadAgo!)
			}
			else {
				return NSLocalizedString("Just now", comment: "")
			}
		}()
		return _0 ? nil : title
	}
	var reusedCellGenerator: TableViewHeightBasedReusedCellGenerator<ItemsListViewController>!
	var rowHeightEstimator: FrequencyAndWeightBasedTableRowHeightEstimator<ItemsListViewController>!
	var systemLayoutSizeCachingDataSource = SystemLayoutSizeCachingTableViewCellDataSource(layoutSizeDefiningValueForCell: { guard $0.reuseIdentifier != "Item" else { return nil }; return $0.reuseIdentifier as NSString? }, cellShouldBeReusedWithoutLayout: {$0.reuseIdentifier != "Item"})
	// MARK: -
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let dt = disableTrace(); defer { _ = dt }
		let reuseIdentifier = reusedCellGenerator?.reuseIdentifierForCellForRowAtIndexPath(indexPath) ?? "Item"
		let cell = tableView.dequeueReusableCell(withIdentifier: $(reuseIdentifier), for: indexPath)
		if nil != reusedCellGenerator {
			(cell as! ItemTableViewCell).systemLayoutSizeCachingDataSource = systemLayoutSizeCachingDataSource
		}
		configureCell(cell, atIndexPath: $(indexPath))
		return cell
	}
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if nil == heightSampleLabel {
			let viewWithVariableHeight = viewWithVariableHeightForCell(cell)
			heightSampleLabel = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: viewWithVariableHeight)) as! UILabel
		}
		let rowHeight = tableView.rectForRow(at: indexPath).height
		reusedCellGenerator?.addRowHeight(rowHeight, forCell: cell, atIndexPath: indexPath)
		rowHeightEstimator?.addRowHeight(rowHeight, forIndexPath: indexPath)
	}
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		guard let rowHeightEstimator = rowHeightEstimator else {
			return UITableViewAutomaticDimension
		}
		guard let estimatedHeight = rowHeightEstimator.estimatedRowHeightForItemAtIndexPath(indexPath) else {
			return UITableViewAutomaticDimension
		}
		return estimatedHeight
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: MainStoryboard.SegueIdentifiers.ShowListPages, sender: self)
	}
	// MARK: -
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		tableView.snapHeaderToTop(animated: true)
	}
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if nil != rssSession && nil != view.superview && !refreshControl!.isRefreshing {
			loadMoreIfNecessary()
		}
	}
	// MARK: -
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowListPages:
			let pageViewController = segue.destination as! UIPageViewController
			let itemsPageViewControllerDataSource = (pageViewController.dataSource as! ItemsPageViewControllerDataSource) … {
				$0.items = fetchedResultsController.fetchedObjects!
			}
			let initialViewController = itemsPageViewControllerDataSource.viewControllerForItem(selectedItem, storyboard: pageViewController.storyboard!)
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				pageViewController.edgesForExtendedLayout = UIRectEdge()
			}
			pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
		default:
			abort()
		}
	}
	private var blocksDelayedTillViewWillAppearOrStateRestoration = [Handler]()
	// MARK: - State Preservation and Restoration
	private enum Restorable: String {
		case containerObjectID = "containerObjectID"
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		container?.encodeObjectIDWithCoder(coder, key: Restorable.containerObjectID.rawValue)
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		container = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.containerObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Container?
		if nil != container {
			nowDate = Date()
		}
		blocksDelayedTillViewWillAppearOrStateRestoration.forEach {$0()}
		blocksDelayedTillViewWillAppearOrStateRestoration = []
	}
	// MARK: -
	private var blocksDelayedTillViewWillAppear = [Handler]()
	// MARK: -
	override func viewWillAppear(_ animated: Bool) {
		$(self)
		nowDate = Date()
		blocksDelayedTillViewWillAppearOrStateRestoration.forEach {$0()}
		blocksDelayedTillViewWillAppearOrStateRestoration = []
		blocksDelayedTillViewWillAppear.forEach {$0()}
		blocksDelayedTillViewWillAppear = []
		blocksDelayedTillViewDidDisappear += [self.bindLoadDate()]
		blocksDelayedTillViewDidDisappear += [self.bindTitle()]
		super.viewWillAppear(animated)
	}
	override func viewDidAppear(_ animated: Bool) {
		$(self)
		super.viewDidAppear(animated)
		loadMoreIfNecessary()
	}
	private var blocksDelayedTillViewDidDisappear = [Handler]()
	override func viewDidDisappear(_ animated: Bool) {
		blocksDelayedTillViewDidDisappear.forEach {$0()}
		blocksDelayedTillViewDidDisappear = []
		super.viewDidDisappear(animated)
	}
	// MARK: -
	func configureFetchedResultsController() {
		fetchedResultsController = regeneratedFetchedResultsController()
		try! $(fetchedResultsController).performFetch()
	}
	func configureTitleHeaderView() {
		if let tableHeaderView = tableView.tableHeaderView {
			if tableView.contentOffset.y == 0 {
				tableView.contentOffset = CGPoint(x: 0, y: (tableHeaderView.frame).height)
			}
		}
	}
	func configureReusableCells() {
		if defaults.cellHeightCachingEnabled {
			let reuseIdentifiersForHeightCachingCells = (0...3).map {"Item-\($0)"}
			for (i, reuseIdentifier) in reuseIdentifiersForHeightCachingCells.enumerated() {
				let cellNib = UINib(nibName: "ItemTableViewCell-\(i)", bundle: nil)
				tableView.register(cellNib, forCellReuseIdentifier: reuseIdentifier)
			}
			reusedCellGenerator = TableViewHeightBasedReusedCellGenerator(dataSource: self, heightAgnosticCellReuseIdentifier: "Item", reuseIdentifiersForHeightCachingCells: reuseIdentifiersForHeightCachingCells)
		}
		let cellNib = UINib(nibName: "ItemTableViewCell", bundle: nil)
		tableView.register(cellNib, forCellReuseIdentifier: "Item")
	}
	func configureRowHeightEstimator() {
		if defaults.frequencyAndWeightBasedTableRowHeightEstimatorEnabled {
			rowHeightEstimator = FrequencyAndWeightBasedTableRowHeightEstimator(dataSource: self)
		}
	}
	func configureRightBarButtonItems() {
		for item in [unfilterUnreadBarButtonItem, filterUnreadBarButtonItem] {
			if let customView = item?.customView {
				customView.layoutIfNeeded()
				customView.sizeToFit()
				let button = customView.subviews.first as! UIButton
				customView.bounds = {
					var $ = customView.bounds
					$.size.width = button.bounds.width
					return $
				}()
				button.frame.origin.x = 0
				item?.width = customView.bounds.width
			}
		}
		loadedRightBarButtonItems = navigationItem.rightBarButtonItems
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
	}
	// MARK: -
	class var keyPathsForValuesAffectingTitleText: Set<String> {
		return [#keyPath(itemsCount)]
	}
	dynamic var titleText: String {
		return "\(itemsCount)"
	}
	func bindTitle() -> Handler {
		let binding = KVOBinding(self•#keyPath(titleText), options: [.initial]) { _ in
			self.navigationItem.title = self.titleText
		}
		return {
			_ = binding
		}
	}
	func bindLoadDate() -> Handler {
		let binding = KVOBinding(self•#keyPath(loadDate), options: [.new, .initial]) { change in
			•(self.toolbarItems!)
			let newValue = change![NSKeyValueChangeKey.newKey]
			if let loadDate = nilForNull(newValue!) as! Date? {
				let loadAgo = loadAgoDateComponentsFormatter.string(from: loadDate, to: Date())
				self.presentInfoMessage(String.localizedStringWithFormat(NSLocalizedString("Updated %@ ago", comment: ""), loadAgo!))
			}
			else {
				self.presentInfoMessage(NSLocalizedString("Not updated before", comment: ""))
			}
		}
		return {_ = binding}
	}
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		configureRowHeightEstimator()
		configureReusableCells()
		blocksDelayedTillViewWillAppearOrStateRestoration += [{ [unowned self] in
			self.configureFetchedResultsController()
		}]
		blocksDelayedTillViewWillAppear += [{[unowned self] in self.configureTitleHeaderView()}]
		tableFooterView = tableView.tableFooterView
		configureRightBarButtonItems()
	}
	var heightSampleLabel: UILabel!
	var cachedVariableHeights: [NSManagedObjectID : CGFloat] = [:]
	// MARK: -
	deinit {
		$(self)
	}
	// MARK: -
	static private let initializeOnce: Void = {
		_Self.adjustForNilIndexPathPassedToModelIdentifierForElement()
	}()
	override public class func initialize() {
		super.initialize()
		_ = initializeOnce
	}
}

extension ItemsListViewController: FrequencyAndWeightBasedTableRowHeightEstimatorDataSource {
	func weightForHeightDefiningValue(atIndexPath indexPath: IndexPath) -> Int {
		let item = fetchedResultsController.object(at: indexPath) 
		let length = item.title.utf16.count
		return length
	}
}

extension ItemsListViewController: TableViewHeightBasedReusedCellGeneratorDataSource {
	func viewWithVariableHeightForCell(_ cell: UITableViewCell) -> UIView {
		let cell = cell as! ItemTableViewCell
		return cell.titleLabel
	}
	func variableHeight(forCell cell: UITableViewCell) -> CGFloat {
		return viewWithVariableHeightForCell(cell).bounds.height
	}
	func isReadyForMeasuringHeigthsForData() -> Bool {
		return nil != heightSampleLabel
	}
	func variableHeightForDataAtIndexPath(_ indexPath: IndexPath) -> CGFloat {
		let item = fetchedResultsController.object(at: indexPath) 
		let cacheKey = item.objectID
		if let cachedHeight = cachedVariableHeights[cacheKey] {
			return cachedHeight
		}
		heightSampleLabel.text = item.title
		let size = heightSampleLabel.sizeThatFits(CGSize(width: heightSampleLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
		let height = size.height
		cachedVariableHeights[cacheKey] = height
		return height
	}
}

extension ItemsListViewController {
	func regeneratedFetchedResultsController() -> NSFetchedResultsController<Item> {
		typealias E = Item
		let fetchRequest = E.fetchRequestForEntity() … {
			$0.sortDescriptors = sortDescriptorsForContainers
			$0.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[NSPredicate]() … { (x: inout [NSPredicate]) in
				x += [container!.predicateForItems]
				x += [containerViewPredicate]
			})
#if false
			$0.relationshipKeyPathsForPrefetching = [#keyPath(E.categories)]
#endif
			$0.returnsObjectsAsFaults = false
			$0.fetchBatchSize = defaults.fetchBatchSize
		}
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainQueueManagedObjectContext, sectionNameKeyPath: !defaults.itemsAreSortedByLoadDate ? nil : #keyPath(Item.loadDate), cacheName: nil)
		let configureCell = { [unowned self] (cell: UITableViewCell, indexPath: IndexPath) -> Void in
			self.configureCell(cell, atIndexPath: indexPath)
		}
		let $ = TableViewFetchedResultsControllerDelegate(tableView: tableView, updateCell: configureCell)
		objc_setAssociatedObject(fetchedResultsController, &fetchedResultsControllerDelegateAOKey, $, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		fetchedResultsController.delegate = $
		return fetchedResultsController
	}
}

// MARK: - UIDataSourceModelAssociation
extension ItemsListViewController: UIDataSourceModelAssociation {
    func modelIdentifierForElement(at indexPath: IndexPath, in view: UIView) -> String? {
		if let item = itemForIndexPath(indexPath) {
			return item.objectID.uriRepresentation().absoluteString
		}
		else {
			let invalidModelIdentifier = ""
			return $(invalidModelIdentifier)
		}
	}
    func indexPathForElement(withModelIdentifier identifier: String, in view: UIView) -> IndexPath? {
		let objectIDURL = URL(string: identifier)!
		let managedObjectContext = fetchedResultsController.managedObjectContext
		assert(managedObjectContext == mainQueueManagedObjectContext)
		let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: objectIDURL)!
		let object = managedObjectContext.object(with: objectID) as! Item
		guard let indexPath = fetchedResultsController.indexPath(forObject: object) else {
			$(object)
			$(fetchedResultsController.fetchRequest)
			$(fetchedResultsController.fetchedObjects)
			return nil
		}
		return $(indexPath)
	}
}

extension ItemsListViewController {
	func presentMessage(_ text: String) {
		statusLabel.text = text
		statusLabel.sizeToFit()
		statusLabel.superview!.frame.size.width = statusLabel.bounds.width
		statusBarButtonItem.width = (statusLabel.superview!.bounds.width)
	}
	override func presentErrorMessage(_ text: String) {
		presentMessage(text)
	}
	override func presentInfoMessage(_ text: String) {
		presentMessage(text)
	}
}
