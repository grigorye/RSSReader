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
	@objc public dynamic var loadController: ContainerLoadController!
	func bindLoadController() -> Handler {
		let loadController = ContainerLoadController(session: rssSession!, container: self.container, unreadOnly: self.showUnreadOnly) … {
			$0.numberOfItemsToLoadInitially = defaults.numberOfItemsToLoadInitially
			$0.numberOfItemsToLoadLater = defaults.numberOfItemsToLoadLater
		}
		self.loadController = loadController
		self.loadController.bind()
		return {
			self.loadController.unbind()
			self.loadController = nil
		}
	}
	final var multipleSourcesEnabled = false
	var showUnreadEnabled = true
	// MARK:-
	var showUnreadOnly = false
	
	// MARK: - ItemsViewControllerLoadingImp
	
	var tableFooterViewOnLoading: UIView!
	
	// MARK: -
	private var loadedRightBarButtonItems: [UIBarButtonItem]!
	@IBOutlet var statusLabel: UILabel!
	@IBOutlet var statusBarButtonItem: UIBarButtonItem!
	@IBOutlet private var filterUnreadBarButtonItem: UIBarButtonItem!
	@IBOutlet private var unfilterUnreadBarButtonItem: UIBarButtonItem!
	
	private func regeneratedRightBarButtonItems() -> [UIBarButtonItem] {
		let excludedItems = showUnreadEnabled ? [(showUnreadOnly ?  filterUnreadBarButtonItem : unfilterUnreadBarButtonItem)!] : [filterUnreadBarButtonItem!, unfilterUnreadBarButtonItem!]
		let x = loadedRightBarButtonItems!.filter { nil == excludedItems.index(of: $0) }
		return x
	}
	
	// MARK: -

	private var loadedToolbarItems: [UIBarButtonItem]!
	
	@IBOutlet private var toBeginningBarButtonItem: UIBarButtonItem!
	@IBOutlet private var toEndBarButtonItem: UIBarButtonItem!
	
	var begEndBarButtonItems: [UIBarButtonItem] {
		return [toBeginningBarButtonItem, toEndBarButtonItem]
	}
	private func regeneratedToolbarItems() -> [UIBarButtonItem] {
		let x = loadedToolbarItems!.filter {
			guard !defaults.begEndBarButtonItemsEnabled else {
				return true
			}
			return !begEndBarButtonItems.contains($0)
		}
		return x
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
				$0.items = dataSource.fetchedObjects!
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
			$0 += [self.bindLoadController()]
			$0 += [self.bindLoadDate()]
			$0 += [self.bindTitle()]
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
	
	private func configureDataSource() {
		let dataSource = ItemTableViewDataSource(tableView: tableView, container: container, showUnreadOnly: showUnreadOnly)
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
		for item in [unfilterUnreadBarButtonItem, filterUnreadBarButtonItem] {
			if let customView = item?.customView {
				customView.layoutIfNeeded()
				customView.sizeToFit()
				let button = customView.subviews.first as! UIButton
				customView.bounds.size.width = button.bounds.width
				button.frame.origin.x = 0
				item?.width = customView.bounds.width
			}
		}
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
	@objc class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [#keyPath(loadController.loadDate)]
	}
	@objc dynamic var loadDate: Date {
		get {
			return loadController.loadDate
		}
	}
	func bindLoadDate() -> Handler {
		let binding = observe(\.loadDate, options: [.initial]) { (_, _) in
			•(self.toolbarItems!)
			if let loadDate = self.loadController.loadDate {
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
		self.refreshControl = UIRefreshControl() … {
			$0.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		}
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
		self.unbind()
		self.bind()
		loadMore {
			refreshControl.endRefreshing()
		}
	}
	@IBAction private func markAllAsRead(_ sender: AnyObject!) {
		let items = container.ownItems
		for i in items {
			i.markedAsRead = true
		}
		firstly { () -> Promise<Void> in
			rssSession!.markAllAsRead(container!)
		}.then { (_) -> Void in
			self.track(.markedAllAsRead)
		}.catch { error in
			self.present(error)
		}
	}
	@IBAction private func scrollToEnd(_ sender: AnyObject?) {
		tableView.scrollToRow(at: IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0), at: .bottom, animated: true)
	}
	@IBAction private func scrollToBeginning(_ sender: AnyObject?) {
		tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
	}
	@IBAction private func action(_ sender: AnyObject?) {
		let activityViewController = UIActivityViewController(activityItems: [container!], applicationActivities: applicationActivities)
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
