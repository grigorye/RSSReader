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

extension KVOCompliantUserDefaults {
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
		case .completed:
			return NSLocalizedString("Completed", comment: "Folders Update State")
		}
	}
}

class FoldersViewController: ContainerViewController, UIDataSourceModelAssociation {
	typealias _Self = FoldersViewController
	dynamic var rootFolder: Folder? {
		set {
			container = newValue
		}
		get {
			return container as! Folder?
		}
	}
	var childContainers: [Container]!
	dynamic let defaults = KVOCompliantUserDefaults()
	//
	class var keyPathsForValuesAffectingShowUnreadOnly: Set<String> {
		return [#keyPath(defaults.showUnreadOnly)]
	}
	private dynamic var showUnreadOnly: Bool {
		return defaults.showUnreadOnly
	}
	//
	class var keyPathsForValuesAffectingRegeneratedChildContainers: Set<String> {
		return [#keyPath(rootFolder.childContainers), #keyPath(showUnreadOnly)]
	}
	private dynamic var regeneratedChildContainers: [Container] {
		let regeneratedChildContainers: [Container] = {
			if let rootFolder = self.rootFolder {
				return (rootFolder.childContainers.array as! [Container]).filter { self.showUnreadOnly ? $0.unreadCount > 0 : true }
			}
			else {
				return []
			}
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
		firstly {
			guard nil != rssSession else {
				throw NotLoggedIn()
			}
			return Promise(value: ())
		}.then {
			return self.rssAccount.authenticate()
		}.then {
			return self.foldersController.updateFolders()
		}.then { () -> Void in
			if nil == self.rootFolder {
				self.rootFolder = $(Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext))
				assert(nil != self.rootFolder)
			}
			self.tableView.reloadData()
		}.always {
			self.refreshControl?.endRefreshing()
		}.catch { updateError in
			switch updateError {
			case RSSSessionError.authenticationFailed(_):
				let adjustedError = AuthenticationFailed()
				self.present(adjustedError)
			default:
				let title = NSLocalizedString("Refresh Failed", comment: "Title for alert on failed refresh")
				self.present(updateError, customTitle: title)
			}
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
			return $(indexPath)
		}
		else {
			let missingObjectIDURL = objectIDURL
			$(missingObjectIDURL)
			return nil
		}
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return childContainers.count
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
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
	private enum Restorable: String {
		case rootFolderObjectID = "rootFolderObjectID"
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		rootFolder?.encodeObjectIDWithCoder(coder, key: Restorable.rootFolderObjectID.rawValue)
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
		let binding = KVOBinding(self•#keyPath(regeneratedChildContainers), options: .initial) { [unowned self] change in
			$(change!)
			self.childContainers = self.regeneratedChildContainers
			self.tableView.reloadData()
		}
		return {_ = binding}
	}
	class var keyPathsForValuesAffectingRefreshStateDescription: Set<String> {
		return [
			#keyPath(rssAccount.authenticationStateRawValue),
			#keyPath(foldersController.foldersUpdateState)
		]
	}
	dynamic var refreshStateDescription: String {
		switch rssAccount.authenticationStateRawValue {
		case .Unknown:
			return ""
		case .InProgress:
			return NSLocalizedString("Authenticating", comment: "")
		case .Failed:
			guard case .Failed(let error) = rssAccount.authenticationState else {
				fatalError()
			}
			return "\(error.localizedDescription)"
		case .Succeeded:
			let foldersUpdateState = foldersController.foldersUpdateState
			switch foldersUpdateState {
			case .completed:
				let foldersController = self.foldersController
				if let foldersUpdateError = foldersController.foldersLastUpdateError {
					return "\(foldersUpdateError)"
				}
				if let foldersLastUpdateDate = foldersController.foldersLastUpdateDate {
					let loadAgo = loadAgoDateComponentsFormatter.string(from: foldersLastUpdateDate, to: Date())!
					return String.localizedStringWithFormat(NSLocalizedString("Updated %@ ago", comment: ""), loadAgo)
				}
				return ""
			default:
				return "\(foldersUpdateState)"
			}
		}
	}
	func bindRefreshStateDescription() -> Handler {
		let binding = KVOBinding(self•#keyPath(refreshStateDescription), options: .initial) { [unowned self] change in
			assert(Thread.isMainThread)
			•(change)
			self.presentInfoMessage(self.refreshStateDescription)
		}
		return {_ = binding}
	}
	func bindCombinedTitle() -> Handler {
		let binding = KVOBinding(self•#keyPath(itemsCount), options: [.initial]) { _ in
			self.combinedBarButtonItem.title = "\(self.itemsCount)"
		}
		return {
			_ = binding
		}
	}
	// MARK: -
	var scheduledForViewWillAppear = ScheduledHandlers()
	override func viewWillAppear(_ animated: Bool) {
		scheduledForViewWillAppear.perform()
		super.viewWillAppear(animated)
		scheduledForViewDidDisappear += [bindChildContainers()]
		scheduledForViewDidDisappear += [bindRefreshStateDescription()]
		scheduledForViewDidDisappear += [bindCombinedTitle()]
	}
	var scheduledForViewDidDisappear = ScheduledHandlers()
	override func viewDidDisappear(_ animated: Bool) {
		scheduledForViewDidDisappear.perform()
		super.viewDidDisappear(animated)
	}
	// MARK: -
	deinit {
		$(self)
	}
	static private let initializeOnce: Ignored = {
		_Self.adjustForNilIndexPathPassedToModelIdentifierForElement()
		return Ignored()
	}()
	override public class func initialize() {
		super.initialize()
		_ = initializeOnce
	}
}

extension FoldersViewController {
	func presentMessage(_ text: String) {
		statusLabel.text = (text)
		statusLabel.sizeToFit()
		statusLabel.superview!.frame.size.width = statusLabel.bounds.width
		statusBarButtonItem.width = (statusLabel.superview!.bounds.width)
		let toolbarItems = self.toolbarItems
		self.toolbarItems = self.toolbarItems?.filter { $0 != statusBarButtonItem }
		self.toolbarItems = toolbarItems
	}
	override func presentErrorMessage(_ text: String) {
		presentMessage(text)
	}
	override func presentInfoMessage(_ text: String) {
		presentMessage(text)
	}
}
