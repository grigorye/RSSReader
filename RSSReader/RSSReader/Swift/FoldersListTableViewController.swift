//
//  FoldersListTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 06.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import PromiseKit
import UIKit
import CoreData

extension KVOCompliantUserDefaults {
	@NSManaged var showUnreadOnly: Bool
}

class FoldersListTableViewController: ContainerTableViewController, UIDataSourceModelAssociation {
	typealias _Self = FoldersListTableViewController
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
	static func viewControllerToPresent(on error: Error, title: String, retryAction: @escaping () -> Void) -> UIViewController {
		let alertController: UIAlertController = {
			let message: String = {
				let localizedDescription: String = {
					switch error {
					case RSSReaderData.RSSSessionError.authenticationFailed:
						return NSLocalizedString("Authentication Failed", comment: "Error description for authentication failure")
					default:
						return (error as NSError).localizedDescription
					}
				}()
				if let localizedRecoverySuggestion = (error as NSError).localizedRecoverySuggestion {
					return String.localizedStringWithFormat(NSLocalizedString("%@ %@", comment: "Error message"), localizedDescription, localizedRecoverySuggestion)
				}
				else {
					return localizedDescription
				}
			}()
			let $ = UIAlertController(title: title, message: message, preferredStyle: .alert) … {
				let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action title for alert on error"), style: .default) { action in
					return
				}
				let retryAlertAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Proceed action title for alert on error"), style: .default) { action in
					retryAction()
					return
				}
				$0.addAction(cancelAction)
				$0.addAction(retryAlertAction)
				$0.preferredAction = retryAlertAction
			}
			return $
		}()
		return alertController
	}
	enum AuthenticationState {
		case Unknown, InProgress, Succeeded, Failed(error: Error?)
	}
	var authenticationState: AuthenticationState = .Unknown {
		didSet {
			self.presentInfoMessage("Authentication\(self.authenticationState)")
		}
	}
	@IBAction func refresh(_ sender: AnyObject!) {
		guard let rssSession = rssSession else {
			let message = NSLocalizedString("To sync you should be logged in.", comment: "")
			presentErrorMessage(message)
			return
		}
		firstly {
			guard !rssSession.authenticated else {
				return Promise(value: ())
			}
			self.authenticationState = .InProgress
			return rssSession.authenticate()
		}.recover { authenticationError -> Void in
			self.authenticationState = .Failed(error: authenticationError)
			throw $(authenticationError)
		}.then {
			self.authenticationState = .Succeeded
			return self.foldersController.updateFoldersAuthenticated()
		}.then { () -> Void in
			if nil == self.rootFolder {
				self.rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext)
				assert(nil != self.rootFolder)
			}
			self.tableView.reloadData()
		}.always {
			self.refreshControl?.endRefreshing()
		}.catch { updateError in
			let presentedError: Error = {
				switch $(updateError) {
				case let foldersControllerError as FoldersControllerError:
					switch foldersControllerError {
					case .userInfoRetrieval(let underlyingError):
						return underlyingError
					default:
						return foldersControllerError
					}
				default:
					return updateError
				}
			}()
			let errorTitle = NSLocalizedString("Refresh Failed", comment: "Title for alert on failed refresh")
			let errorViewController = type(of: self).viewControllerToPresent(on: presentedError, title: errorTitle) {
				self.refresh(self)
			}
			self.present(errorViewController, animated: true, completion: nil)
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
		case MainStoryboard.SegueIdentifiers.ShowFolder:
			let foldersListTableViewController = segue.destination as! FoldersListTableViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow!
			let folder = childContainers[indexPathForSelectedRow.row] as! Folder
			foldersListTableViewController.rootFolder = folder
		case MainStoryboard.SegueIdentifiers.ShowSubscription:
			let itemsListViewController = segue.destination as! ItemsListViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow!
			let subscription = childContainers[indexPathForSelectedRow.row] as! Subscription
			itemsListViewController.container = subscription
		case MainStoryboard.SegueIdentifiers.ShowCombined:
			let itemsListViewController = segue.destination as! ItemsListViewController
			itemsListViewController.container = self.rootFolder
			itemsListViewController.multipleSourcesEnabled = true
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
			let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.ReuseIdentifiers.Subscription, for: indexPath)
			self.configureCell(cell, forSubscription: subscription)
			return cell
		case let folder as Folder:
			let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.ReuseIdentifiers.Folder, for: indexPath)
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
	func bindFoldersUpdateState() -> Handler {
		let binding = KVOBinding(self•#keyPath(foldersController.foldersUpdateStateRaw), options: .initial) { [unowned self] change in
			assert(Thread.isMainThread)
			•(change)
			let foldersUpdateState = self.foldersController.foldersUpdateState
			let message: String = {
				switch foldersUpdateState {
				case .completed:
					let foldersController = self.foldersController
					if let foldersUpdateError = foldersController.foldersLastUpdateError {
						return "\(foldersUpdateError)"
					}
					else if let foldersLastUpdateDate = foldersController.foldersLastUpdateDate {
						let loadAgo = loadAgoDateComponentsFormatter.string(from: foldersLastUpdateDate, to: Date())!
						return String.localizedStringWithFormat(NSLocalizedString("Updated %@ ago", comment: ""), loadAgo)
					}
					else {
						return ""
					}
				default:
					return "\(foldersUpdateState)"
				}
			}()
			self.presentInfoMessage(message)
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
	var blocksScheduledForViewWillAppear = [Handler]()
	override func viewWillAppear(_ animated: Bool) {
		blocksScheduledForViewWillAppear.forEach {$0()}
		blocksScheduledForViewWillAppear = []
		super.viewWillAppear(animated)
		blocksScheduledForViewDidDisappear += [bindChildContainers()]
		blocksScheduledForViewDidDisappear += [bindFoldersUpdateState()]
		blocksScheduledForViewDidDisappear += [bindCombinedTitle()]
	}
	var blocksScheduledForViewDidDisappear = [Handler]()
	override func viewDidDisappear(_ animated: Bool) {
		blocksScheduledForViewDidDisappear.forEach {$0()}
		blocksScheduledForViewDidDisappear = []
		super.viewDidDisappear(animated)
	}
	// MARK: -
	deinit {
		$(self)
	}
	static private let initializeOnce: Void = {
		_Self.adjustForNilIndexPathPassedToModelIdentifierForElement()
	}()
	override public class func initialize() {
		super.initialize()
		_ = initializeOnce
	}
}

extension FoldersListTableViewController {
	func presentMessage(_ text: String) {
		statusLabel.text = (text)
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
