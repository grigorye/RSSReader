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

class ItemsListViewController: ContainerTableViewController {
	typealias _Self = ItemsListViewController
	public var dataSource: ItemTableViewDataSource!
	public var loadController: ContainerLoadController!
	final var multipleSourcesEnabled = false
	var showUnreadEnabled = true
	var systemLayoutSizeCachingDataSource = SystemLayoutSizeCachingTableViewCellDataSource(layoutSizeDefiningValueForCell: { guard $0.reuseIdentifier != "Item" else { return nil }; return $0.reuseIdentifier as NSString? }, cellShouldBeReusedWithoutLayout: {$0.reuseIdentifier != "Item"})
	//
	var containerViewStateRetained: RSSReaderData.ContainerViewState?
	// MARK:- ItemListViewLoading
	var ongoingLoadDate: Date?
	// MARK:-
	var showUnreadOnly = false
	var containerViewPredicate: NSPredicate {
		return dataSource.containerViewPredicate
	}
	var loadInProgress = false
	//
	var tableFooterView: UIView?
	private var indexPathForTappedAccessoryButton: IndexPath?
	// MARK: -
	private var loadedRightBarButtonItems: [UIBarButtonItem]!
	@IBOutlet var statusLabel: UILabel!
	@IBOutlet var statusBarButtonItem: UIBarButtonItem!
	@IBOutlet private var filterUnreadBarButtonItem: UIBarButtonItem!
	@IBOutlet private var unfilterUnreadBarButtonItem: UIBarButtonItem!
	private func regeneratedRightBarButtonItems() -> [UIBarButtonItem] {
		let excludedItems = showUnreadEnabled ? [(showUnreadOnly ?  filterUnreadBarButtonItem : unfilterUnreadBarButtonItem)!] : [filterUnreadBarButtonItem!, unfilterUnreadBarButtonItem!]
		let $ = loadedRightBarButtonItems.filter { nil == excludedItems.index(of: $0) }
		return $
	}
	// MARK: -
	func reloadViewForNewConfiguration() {
		navigationItem.rightBarButtonItems = regeneratedRightBarButtonItems()
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
		case MainStoryboard.SegueIdentifiers.ShowListPages:
			let pageViewController = segue.destination as! UIPageViewController
			let itemsPageViewControllerDataSource = (pageViewController.dataSource as! ItemsPageViewControllerDataSource) … {
				$0.items = dataSource.fetchedObjects!
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
	var blocksDelayedTillViewWillAppearOrStateRestoration = [Handler]()
	// MARK: -
	private var blocksDelayedTillViewWillAppear = [Handler]()
	// MARK: -
	override func viewWillAppear(_ animated: Bool) {
		$(self)
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
	func configureDataSource() {
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
		blocksDelayedTillViewWillAppearOrStateRestoration += [{ [unowned self] in
			self.configureDataSource()
			self.configureRightBarButtonItems()
		}]
		blocksDelayedTillViewWillAppear += [{[unowned self] in self.configureTitleHeaderView()}]
		tableFooterView = tableView.tableFooterView
		if #available(iOS 10.0, *) {
			tableView.prefetchDataSource = self
		}
		if defaults.fixedHeightItemRowsEnabled {
			tableView.rowHeight = 44
		}
	}
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
//
// MARK: - State Restoration
//
extension ItemsListViewController /* State Restoration */ {
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
		blocksDelayedTillViewWillAppearOrStateRestoration.forEach {$0()}
		blocksDelayedTillViewWillAppearOrStateRestoration = []
	}
}
//
// MARK: - Actions
//
extension ItemsListViewController {
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
		guard !(loadInProgress && $(nil == continuation)) else {
			refreshControl.endRefreshing()
			return
		}
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
}
//
// MARK: - Scroll & Table View Delegate Additions
//
extension ItemsListViewController {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: MainStoryboard.SegueIdentifiers.ShowListPages, sender: self)
	}
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		tableView.snapHeaderToTop(animated: true)
	}
}
//
// MARK: - Presenting Messages
//
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

