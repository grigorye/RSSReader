//
//  ItemsViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEUIKit
import PromiseKit
import UIKit
import CoreData

extension TypedUserDefaults {
	
	@NSManaged var itemPrefetchingEnabled: Bool
	
}

extension TypedUserDefaults {
	
	@NSManaged var begEndBarButtonItemsEnabled: Bool
	
}

class ItemsViewController : ContainerViewController {

	typealias _Self = ItemsViewController

	lazy var prototypeCell = R.nib.itemTableViewCell.firstView(owner: nil)!

	public var dataSource: ItemTableViewDataSource!
	
	var refreshing = false
	
	open var canLoadItems: Bool {
		return true
	}
	
	@objc public dynamic var loadController: ContainerLoadController?
	func bindLoadController() -> Handler {
		guard let rssSession = rssSession else {
			return {}
		}
		let loadController = ContainerLoadController(session: rssSession, container: self.container, unreadOnly: self.showUnreadOnly, forceReload: refreshing) … {
			$0.numberOfItemsToLoadInitially = defaults.numberOfItemsToLoadInitially
			$0.numberOfItemsToLoadLater = defaults.numberOfItemsToLoadLater
		}
		self.loadController = loadController
		loadController.bind()
		return {
			loadController.unbind()
			self.loadController = nil
		}
	}
	var loadCancellation: (() -> Void)? = nil

	final var multipleSourcesEnabled = false
	var showUnreadEnabled = true
	// MARK:-
	var showUnreadOnly = false
	
	// MARK: - ItemsViewControllerLoadingImp
	
	var tableFooterViewOnLoading: UIView!
	
	// MARK: -
	private var loadedRightBarButtonItems: [UIBarButtonItem]!
	@IBOutlet var statusLabel: UILabel?
	@IBOutlet var statusBarButtonItem: UIBarButtonItem!
	@IBOutlet private var filterUnreadBarButtonItem: UIBarButtonItem!
	@IBOutlet private var unfilterUnreadBarButtonItem: UIBarButtonItem!
	
	private func filterOutUnreadBarButtonItems(_ x: [UIBarButtonItem]) -> [UIBarButtonItem] {
		
		let excludedItems: [UIBarButtonItem] = {
			guard let filterUnreadBarButtonItem = filterUnreadBarButtonItem else {
				return []
			}
			guard let unfilterUnreadBarButtonItem = unfilterUnreadBarButtonItem else {
				return []
			}
			return showUnreadEnabled ? [(showUnreadOnly ?  filterUnreadBarButtonItem : unfilterUnreadBarButtonItem)] : [filterUnreadBarButtonItem, unfilterUnreadBarButtonItem]
		}()
		return x.filter { nil == excludedItems.index(of: $0) }
	}
	
	private func regeneratedRightBarButtonItems() -> [UIBarButtonItem]? {
		
		return filterOutUnreadBarButtonItems(loadedRightBarButtonItems ?? [])
	}
	
	// MARK: -

	private var loadedToolbarItems: [UIBarButtonItem]!
	
	@IBOutlet private var toBeginningBarButtonItem: UIBarButtonItem!
	@IBOutlet private var toEndBarButtonItem: UIBarButtonItem!
	
	var begEndBarButtonItems: [UIBarButtonItem] {
		return [toBeginningBarButtonItem, toEndBarButtonItem]
	}
	private func regeneratedToolbarItems() -> [UIBarButtonItem]? {
		let x = loadedToolbarItems?.filter {
			guard !defaults.begEndBarButtonItemsEnabled else {
				return true
			}
			return !begEndBarButtonItems.contains($0)
		}
		return filterOutUnreadBarButtonItems(x ?? [])
	}

	// MARK: -
	func reloadViewForNewConfiguration() {
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
		toolbarItems = regeneratedToolbarItems()
		self.unbind()
		self.loadController = nil
		self.bind()
		configureDataSource()
		tableView.reloadData()
		loadMoreIfNecessary()
	}
	// MARK: -
	func itemForIndexPath(_ indexPath: IndexPath!) -> Item! {
		if nil != indexPath {
			return dataSource.object(at: indexPath)
		}
		else {
			return nil
		}
	}
	private var selectedItem: Item {
		return itemForIndexPath(tableView.indexPathForSelectedRow!)
	}
	
	// MARK: -
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier! {
		case R.segue.itemsViewController.showListPages.identifier:
			let pageViewController = segue.destination as? UIPageViewController ?? segue.destination.childViewControllers.last as! UIPageViewController
			let itemPageViewControllerDataSource = (pageViewController.dataSource as! ItemPageViewControllerDataSource) … {
				$0.itemsController = dataSource.fetchedResultsController
			}
			pageViewController … {
				if floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1 {
					$0.edgesForExtendedLayout = UIRectEdge()
				}
				let initialViewController = itemPageViewControllerDataSource.viewControllerForItem(selectedItem)
				$0.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
				$0.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
				$0.navigationItem.leftItemsSupplementBackButton = true
			}

		default:
			abort()
		}
	}
	
	// MARK: -
	
	var scheduledForViewWillAppearOrStateRestoration = ScheduledHandlers()
	
	// MARK: -
	
	private var visibleStateReasoner = ViewControllerVisibleStateReasoner()
	
	// MARK: -
	
	var scheduledForUnbind = ScheduledHandlers()
	
	func bind() {
		precondition(!scheduledForUnbind.hasHandlers)
		scheduledForUnbind = ScheduledHandlers() … {
			if canLoadItems {
				$0 += [self.bindLoadController()]
				$0 += [self.bindLoadDate()]
			}
			if defaults.showContainerTitleInTableHeader {
				$0 += [self.bindTitle()]
			}
		}
	}
	
	func unbind() {
		scheduledForUnbind.perform()
	}
	
	// MARK: -

	override func viewWillAppear(_ animated: Bool) {
		scheduledForViewWillAppearOrStateRestoration.perform()
		scheduledForViewWillAppear.perform()
		
		super.viewWillAppear(animated)
		visibleStateReasoner.viewWillAppear()
		
		guard !visibleStateReasoner.appeared else {
			return
		}
		
		self.bind()
		scheduledForViewDidDisappear += [{self.unbind()}]
	}
	private var scheduledForViewWillAppear = ScheduledHandlers()
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		visibleStateReasoner.viewWillDisappear()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		visibleStateReasoner.viewDidAppear()
		
		loadMoreIfNecessary()
	}

	override func viewDidDisappear(_ animated: Bool) {
		scheduledForViewDidDisappear.perform()
		super.viewDidDisappear(animated)
		visibleStateReasoner.viewDidDisappear()
	}
	var scheduledForViewDidDisappear = ScheduledHandlers()
	
	// MARK: -
	
	open var predicate: NSPredicate {
		return showUnreadOnly ? predicateForUnreadOnly() : NSPredicate(value: true)
	}

	open var sortDescriptors: [NSSortDescriptor] {
		return sortDescriptorsForContainers
	}

	private func configureDataSource() {
		let dataSource = ItemTableViewDataSource(tableView: tableView, container: container, predicate: predicate, sortDescriptors: sortDescriptors)
		tableView.dataSource = dataSource
		self.dataSource = dataSource
		try! dataSource.performFetch()
	}
	func configureTitleHeaderView() {
		if let tableHeaderView = tableView.tableHeaderView {
			if tableView.contentOffset.y == 0 {
				tableView.contentOffset = CGPoint(x: 0, y: (tableHeaderView.frame).height)
			}
		}
	}
	
	func configureToolbarItems() {
		loadedToolbarItems = toolbarItems
		toolbarItems = regeneratedToolbarItems()
	}
	
	func configureRightBarButtonItems() {
		loadedRightBarButtonItems = navigationItem.rightBarButtonItems
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
	}
	
	// MARK: -
	@objc class var keyPathsForValuesAffectingTitleText: Set<String> {
		return [#keyPath(itemsCount)]
	}
	@objc dynamic var titleText: String {
		return "\(itemsCount)"
	}
	func bindTitle() -> Handler {
		let binding = self.observe(\.titleText, options: [.initial]) { (_, _) in
			self.navigationItem.title = self.titleText
		}
		return {
			_ = binding
		}
	}
	var loadDate: Date?
	func bindLoadDate() -> Handler {
		let binding = container.bindLoadDate(unreadOnly: showUnreadOnly) {
			•(self.toolbarItems!)
			self.loadDate = $0
			if let loadDate = self.loadDate {
				self.track(.updated(at: loadDate))
			}
			else {
				self.track(.notUpdatedBefore)
			}
		}
		return {_ = binding}
	}
	// MARK: -
	func configureTableViewRowHeight() {
		tableView.estimatedRowHeight = 44
		tableView.rowHeight = {
			guard !defaults.fixedHeightItemRowsEnabled else {
				return 44
			}
			return UITableViewAutomaticDimension
		}()
	}
	func configureTableViewPrefetching() {
		guard defaults.itemPrefetchingEnabled, #available(iOS 10.0, *) else {
			return
		}
		tableView.prefetchDataSource = self
	}
	func configureLoading() {
		let tableFooterView = R.nib.itemTableViewFooter.firstView(owner: self)
		tableView.tableFooterView = tableFooterView
		self.tableFooterViewOnLoading = tableView.tableFooterView
		tableView.tableFooterView = nil
		if canLoadItems {
			self.refreshControl = UIRefreshControl() … {
				$0.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
			}
		}
	}

	override func loadView() {
		self.tableView = ItemTableView()
	}
	
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.configureTableViewRowHeight()
		self.configureTableViewPrefetching()
		self.configureLoading()

		scheduledForViewWillAppearOrStateRestoration += [{ [unowned self] in
			self.configureDataSource()
			self.configureRightBarButtonItems()
			self.configureToolbarItems()
		}]

		scheduledForViewWillAppear += [{ [unowned self] in
			self.configureTitleHeaderView()
		}]
	}
	// MARK: -
	deinit {
		x$(self)
	}
	// MARK: -
	static private let initializeOnce: Ignored = {
		_Self.adjustForNilIndexPathPassedToModelIdentifierForElement()
		return Ignored()
	}()
	required init?(coder aDecoder: NSCoder) {
		_ = ItemsViewController.initializeOnce
		super.init(coder: aDecoder)
	}
}
//
// MARK: - State Restoration
//
extension ItemsViewController /* State Restoration */ {
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		scheduledForViewWillAppearOrStateRestoration.perform()
	}
}
//
// MARK: - Actions
//
extension ItemsViewController {
	@IBAction private func selectUnread(_ sender: AnyObject!) {
		showUnreadOnly = true
		reloadViewForNewConfiguration()
	}
	@IBAction private func unselectUnread(_ sender: AnyObject!) {
		showUnreadOnly = false
		reloadViewForNewConfiguration()
	}
	@IBAction fileprivate func refresh(_ sender: AnyObject!) {
		guard let refreshControl = refreshControl else {
			fatalError()
		}
		#if false
		guard !loadController.loadInProgress else {
			return
		}
		#endif
		if let loadCancellation = loadCancellation {
			loadCancellation()
		}
		self.unbind()
		self.refreshing = true
		self.bind()
		assert(nil == loadCancellation)
		loadCancellation = loadMore {
			self.loadCancellation = nil
			refreshControl.endRefreshing()
		}
	}
	@IBAction private func markAllAsRead(_ sender: AnyObject!) {
		guard let rssSession = rssSession else {
			return
		}
		let items = container.ownItems
		for i in items {
			i.markedAsRead = true
		}
		firstly { () -> Promise<Void> in
			rssSession.markAllAsRead(container)
		}.then { (_) -> Void in
			self.track(.markedAllAsRead)
		}.catch { error in
			self.present(error)
		}
	}
	@IBAction private func scrollToEnd(_ sender: AnyObject?) {
		let numberOfRows = tableView.numberOfRows(inSection: 0)
		guard 0 < numberOfRows else {
			return
		}
		tableView.scrollToRow(at: IndexPath(row: numberOfRows - 1, section: 0), at: .bottom, animated: true)
	}
	@IBAction private func scrollToBeginning(_ sender: AnyObject?) {
		guard 0 < tableView.numberOfRows(inSection: 0) else {
			return
		}
		tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
	}
	@IBAction private func action(_ sender: AnyObject?) {
		let activityViewController = UIActivityViewController(activityItems: [container], applicationActivities: applicationActivities)
		navigationController?.present(activityViewController, animated: true, completion: nil)
	}
}
//
// MARK: - Scroll & Table View Delegate Additions
//
extension ItemsViewController {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: R.segue.itemsViewController.showListPages, sender: self)
	}
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		tableView.snapHeaderToTop(animated: true)
	}
}
