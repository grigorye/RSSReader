//
//  FolderListTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 06.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import func GEUIKit.openSettingsApp
import protocol GEFoundation.RecoverableError
import struct GEFoundation.RecoveryOption
import PromiseKit
import UIKit
import CoreData

extension TypedUserDefaults {
	@NSManaged var showUnreadOnly: Bool
}

class NotLoggedIn : RecoverableError, LocalizedError {
	var recoveryOptions: [RecoveryOption] = [
		RecoveryOption(title: NSLocalizedString("Open Settings", comment: "")) {
			openSettingsApp()
			return true
		},
		RecoveryOption(title: NSLocalizedString("Cancel", comment: "")) {
			return false
		}
	]
	var errorDescription: String? = NSLocalizedString("Could not proceed as account information is missing.", comment: "")
	var failureReason: String? = NSLocalizedString("You are not logged in.", comment: "")
	var recoverySuggestion: String? = NSLocalizedString("To enable login, open this app's settings and fill \"Login and Password\".", comment: "")
}

class AuthenticationFailed : RecoverableError, LocalizedError {

	var recoveryOptions: [RecoveryOption] = [
		RecoveryOption(title: NSLocalizedString("Open Settings", comment: "")) {
			openSettingsApp()
			return true
		},
		RecoveryOption(title: NSLocalizedString("Cancel", comment: "")) {
			return false
		}
	]
	
	var errorDescription: String? = NSLocalizedString("Could not proceed as username or password is invalid.", comment: "")
	var failureReason: String? = NSLocalizedString("You are not logged in.", comment: "")
	var recoverySuggestion: String? = NSLocalizedString("To adjust the username or password, open this app's settings and edit \"Login and Password\".", comment: "")
	
}

extension FoldersUpdateState : CustomStringConvertible {
	public var description: String {
		switch self {
		case .unknown:
			return NSLocalizedString("Unknown", comment: "Folders Update State")
		case .updatingUserInfo:
			return NSLocalizedString("Updating User Info", comment: "Folders Update State")
		case .pushingTags:
			return NSLocalizedString("Pushing Tags", comment: "Folders Update State")
		case .pullingTags:
			return NSLocalizedString("Pulling Tags", comment: "Folders Update State")
		case .updatingSubscriptions:
			return NSLocalizedString("Updating Subscriptions", comment: "Folders Update State")
		case .updatingUnreadCounts:
			return NSLocalizedString("Updating Unread Counts", comment: "Folders Update State")
		case .updatingStreamPreferences:
			return NSLocalizedString("Updating Folder List", comment: "Folders Update State")
		case .prefetching:
			return NSLocalizedString("Prefetching", comment: "Folders Update State")
		case .ended:
			return NSLocalizedString("Update Ended", comment: "Folders Update State")
		}
	}
}

class FoldersViewController: ContainerViewController, UIDataSourceModelAssociation {
	typealias _Self = FoldersViewController
	@objc dynamic var rootFolder: Folder {
		set {
			container = newValue
		}
		get {
			return container as! Folder
		}
	}
	var childContainers: [Container]!
	@objc dynamic let defaults = TypedUserDefaults()
	//
	@objc class var keyPathsForValuesAffectingShowUnreadOnly: Set<String> {
		return [#keyPath(defaults.showUnreadOnly)]
	}
	@objc private dynamic var showUnreadOnly: Bool {
		return defaults.showUnreadOnly
	}
	//
	@objc class var keyPathsForValuesAffectingRegeneratedChildContainers: Set<String> {
		return [#keyPath(rootFolder.childContainers), #keyPath(showUnreadOnly)]
	}
	@objc private dynamic var regeneratedChildContainers: [Container] {
		let regeneratedChildContainers: [Container] = {
			return (rootFolder.childContainers.array as! [Container]).filter { self.showUnreadOnly ? $0.unreadCount > 0 : true }
		}()
		return (regeneratedChildContainers)
	}
	// MARK: -
	@IBOutlet private var combinedBarButtonItem: UIBarButtonItem!
	// MARK: -
	@IBOutlet var statusLabel: UILabel!
	@IBOutlet var statusBarButtonItem: UIBarButtonItem!
	@IBAction func refreshFromBarButtonItem(_ sender: AnyObject!) {
		let refreshControl = self.refreshControl
		refreshControl?.beginRefreshing()
		self.refresh(refreshControl)
	}

	@IBAction func refresh(_ sender: AnyObject!) {
		guard !refreshController.refreshingSubscriptions else {
			track(.secondRefreshIgnored())
			return
		}
		track(.refreshInitiated())
		refreshController.refreshSubscriptions { (error) in
			defer {
				self.refreshControl?.endRefreshing()
				self.track(.refreshCompleted())
			}
			if nil == error {
				if RSSReader.fakeRootFolder() == self.rootFolder {
					self.rootFolder = RSSReader.rootFolder()!
				}
			}
			self.tableView.reloadData()
		}
	}
	
	// MARK: -
	private func configureCell(_ cell: UITableViewCell, forFolder folder: Folder) {
		(cell as! TableViewContainerCell).setFromContainer(folder)
		cell.textLabel?.text = (folder.streamID as NSString).lastPathComponent
	}
	private func configureCell(_ cell: UITableViewCell, forSubscription subscription: Subscription) {
		(cell as! TableViewContainerCell).setFromContainer(subscription)
		cell.textLabel?.text = subscription.title /*?? subscription.url?.lastPathComponent*/
	}
	// MARK: -
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier! {
		case R.segue.foldersViewController.showFolder.identifier:
			let foldersViewController = segue.destination as! FoldersViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow!
			let folder = childContainers[indexPathForSelectedRow.row] as! Folder
			foldersViewController.rootFolder = folder
		case R.segue.foldersViewController.showSubscription.identifier:
			let itemsViewController = segue.destination as! ItemsViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow!
			let subscription = childContainers[indexPathForSelectedRow.row] as! Subscription
			itemsViewController.container = subscription
		case R.segue.foldersViewController.showCombined.identifier:
			let itemsViewController = segue.destination as! ItemsViewController
			itemsViewController.container = self.rootFolder
			itemsViewController.multipleSourcesEnabled = true
		default:
			abort()
		}
	}
	// MARK: -
    func modelIdentifierForElement(at indexPath: IndexPath, in view: UIView) -> String? {
		let childContainer = childContainers[indexPath.row]
		return childContainer.objectID.uriRepresentation().absoluteString
	}
    func indexPathForElement(withModelIdentifier identifier: String, in view: UIView) -> IndexPath? {
		let objectIDURL = URL(string: identifier)!
		if let row = (childContainers.map { return $0.objectID.uriRepresentation().absoluteString }).index(where: { $0 == identifier }) {
			let indexPath = IndexPath(row: row, section: 0)
			return x$(indexPath)
		}
		else {
			let missingObjectIDURL = objectIDURL
			x$(missingObjectIDURL)
			return nil
		}
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return childContainers.count
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let childContainer = childContainers[indexPath.row]
		switch childContainer {
		case let subscription as Subscription:
			let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.subscription, for: indexPath)!
			self.configureCell(cell, forSubscription: subscription)
			return cell
		case let folder as Folder:
			let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.folder, for: indexPath)!
			self.configureCell(cell, forFolder: folder)
			return cell
		default:
			abort()
		}
	}
	// MARK: - State Preservation and Restoration
	private enum Restorable : String {
		case rootFolderObjectID
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		rootFolder.encodeObjectIDWithCoder(coder, key: Restorable.rootFolderObjectID.rawValue)
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		if let rootFolder = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.rootFolderObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Folder? {
			self.rootFolder = rootFolder
			self.childContainers = self.regeneratedChildContainers
		}
	}
	// MARK: -
	func bindChildContainers() -> Handler {
		let binding = self.observe(\.regeneratedChildContainers, options: .initial) { [unowned self] (_, change) in
			x$(change)
			self.childContainers = self.regeneratedChildContainers
			self.tableView.reloadData()
		}
		return {_ = binding}
	}
	
	func bindCombinedTitle() -> Handler {
		let binding = self.observe(\.itemsCount, options: [.initial]) { (_, _) in
			self.combinedBarButtonItem.title = "\(self.itemsCount)"
		}
		return {
			_ = binding
		}
	}
	func bindTrackRefreshState() -> Handler {
		let refreshingStateTracker = RefreshingStateTracker { (message) in
			self.presentInfoMessage(message)
		}
		let unbind = refreshingStateTracker.bind()
		return {
			unbind()
			_ = refreshingStateTracker
		}
	}
	// MARK: -
	var scheduledForViewWillAppear = ScheduledHandlers()
	override func viewWillAppear(_ animated: Bool) {
		scheduledForViewWillAppear.perform()
		super.viewWillAppear(animated)
		scheduledForViewDidDisappear += [bindChildContainers()]
		scheduledForViewDidDisappear += [bindTrackRefreshState()]
		scheduledForViewDidDisappear += [bindCombinedTitle()]
	}
	var scheduledForViewDidDisappear = ScheduledHandlers()
	override func viewDidDisappear(_ animated: Bool) {
		scheduledForViewDidDisappear.perform()
		super.viewDidDisappear(animated)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = 44
		tableView.rowHeight = UITableViewAutomaticDimension
		if !defaults.showMessagesInToolbar {
			toolbarItems = toolbarItems?.filter { $0 != statusBarButtonItem }
		}
	}
	// MARK: -
	deinit {
		x$(self)
	}
	static private let initializeOnce: Ignored = {
		_Self.adjustForNilIndexPathPassedToModelIdentifierForElement()
		return Ignored()
	}()
	required init?(coder aDecoder: NSCoder) {
		_ = FoldersViewController.initializeOnce
		super.init(coder: aDecoder)
	}
}
