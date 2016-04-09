//
//  FoldersListTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 06.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import GEKeyPaths
import UIKit
import CoreData

class FoldersListTableViewController: UITableViewController, UIDataSourceModelAssociation {
	dynamic var rootFolder: Folder?
	var childContainers: [Container]!
	dynamic let defaults = KVOCompliantUserDefaults()
	//
	class var keyPathsForValuesAffectingShowUnreadOnly: Set<String> {
		return [self••{$0.defaults.showUnreadOnly}]
	}
	private dynamic var showUnreadOnly: Bool {
		return defaults.showUnreadOnly
	}
	//
	class var keyPathsForValuesAffectingRegeneratedChildContainers: Set<String> {
		return [self••{$0.rootFolder!.childContainers}, self••{$0.showUnreadOnly}]
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
	@IBOutlet private var statusLabel: UILabel!
	@IBOutlet private var statusBarButtonItem: UIBarButtonItem!
	@IBAction func refreshFromBarButtonItem(sender: AnyObject!) {
		let refreshControl = self.refreshControl
		refreshControl?.beginRefreshing()
		self.refresh(refreshControl)
	}
	static func viewControllerForErrorOnRefresh(error: NSError, retryAction: () -> Void) -> UIViewController {
		let alertController: UIAlertController = {
			let message: String = {
				let localizedDescription = error.localizedDescription
				if let localizedRecoverySuggestion = error.localizedRecoverySuggestion {
					return String.localizedStringWithFormat(NSLocalizedString("%@ %@", comment: "Error message on failed refresh"), localizedDescription, localizedRecoverySuggestion)
				}
				else {
					return localizedDescription
				}
			}()
			let title = NSLocalizedString("Refresh Failed", comment: "Title for alert on failed refresh")
			let $ = UIAlertController(title: title, message: message, preferredStyle: .Alert)
			let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Proceed action title for alert on failed refresh"), style: .Default) { action in
				return
			}
			let retryAlertAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Proceed action title for alert on failed refresh"), style: .Default) { action in
				retryAction()
				return
			}
			$.addAction(cancelAction)
			$.addAction(retryAlertAction)
			$.preferredAction = retryAlertAction
			return $
		}()
		return alertController
	}
	@IBAction func refresh(sender: AnyObject!) {
		guard nil != self.rssSession else {
			let message = NSLocalizedString("To sync you should be logged in.", comment: "")
			presentErrorMessage(message)
			return
		}
		RSSReader.foldersController.updateFolders { updateError in dispatch_async(dispatch_get_main_queue()) {
			if let foldersControllerError = updateError as? FoldersControllerError {
				let error: ErrorType = {
					switch foldersControllerError {
					case .UserInfoRetrieval(let underlyingError):
						return underlyingError
					default:
						return foldersControllerError
					}
				}()
				let errorViewController = self.dynamicType.viewControllerForErrorOnRefresh(error as NSError) {
					self.refresh(self)
				}
				self.presentViewController(errorViewController, animated: true, completion: nil)
			}
			else if let error = updateError as NSError? {
				let errorViewController = self.dynamicType.viewControllerForErrorOnRefresh(error) {
					self.refresh(self)
				}
				self.presentViewController(errorViewController, animated: true, completion: nil)
			}
			else if nil != updateError {
				$(updateError)
			}
			else {
				if nil == self.rootFolder {
					self.rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext)
					assert(nil != self.rootFolder)
				}
				self.tableView.reloadData()
			}
			self.refreshControl?.endRefreshing()
		}}
	}
	// MARK: -
	private func configureCell(cell: UITableViewCell, forFolder folder: Folder) {
		(cell as! TableViewContainerCell).setFromContainer(folder)
		cell.textLabel?.text = (folder.streamID as NSString).lastPathComponent
	}
	private func configureCell(cell: UITableViewCell, forSubscription subscription: Subscription) {
		(cell as! TableViewContainerCell).setFromContainer(subscription)
		cell.textLabel?.text = subscription.title ?? subscription.url?.lastPathComponent
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowFolder:
			let foldersListTableViewController = segue.destinationViewController as! FoldersListTableViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow!
			let folder = childContainers[indexPathForSelectedRow.row] as! Folder
			foldersListTableViewController.rootFolder = folder
		case MainStoryboard.SegueIdentifiers.ShowSubscription:
			let itemsListViewController = segue.destinationViewController as! ItemsListViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow!
			let subscription = childContainers[indexPathForSelectedRow.row] as! Subscription
			itemsListViewController.container = subscription
		case MainStoryboard.SegueIdentifiers.ShowCombined:
			let itemsListViewController = segue.destinationViewController as! ItemsListViewController
			itemsListViewController.container = self.rootFolder
			itemsListViewController.multipleSourcesEnabled = true
		default:
			abort()
		}
	}
	// MARK: -
    func modelIdentifierForElementAtIndexPath(indexPath: NSIndexPath, inView view: UIView) -> String? {
		let childContainer = childContainers[indexPath.row]
		return childContainer.objectID.URIRepresentation().absoluteString
	}
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
		let objectIDURL = NSURL(string: identifier)!
		if let row = (childContainers.map { return $0.objectID.URIRepresentation().absoluteString }).indexOf(identifier) {
			let indexPath = NSIndexPath(forRow: row, inSection: 0)
			return $(indexPath)
		}
		else {
			let missingObjectIDURL = objectIDURL
			$(missingObjectIDURL)
			return nil
		}
	}
	// MARK: -
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return childContainers.count
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let childContainer = childContainers[indexPath.row]
		switch childContainer {
		case let subscription as Subscription:
			let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.ReuseIdentifiers.Subscription, forIndexPath: indexPath)
			self.configureCell(cell, forSubscription: subscription)
			return cell
		case let folder as Folder:
			let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.ReuseIdentifiers.Folder, forIndexPath: indexPath)
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
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		rootFolder?.encodeObjectIDWithCoder(coder, key: Restorable.rootFolderObjectID.rawValue)
	}
	override func decodeRestorableStateWithCoder(coder: NSCoder) {
		super.decodeRestorableStateWithCoder(coder)
		if let rootFolder = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.rootFolderObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Folder? {
			self.rootFolder = rootFolder
			self.childContainers = self.regeneratedChildContainers
		}
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	var blocksScheduledForViewWillAppear = [Handler]()
	override func viewWillAppear(animated: Bool) {
		for i in blocksScheduledForViewWillAppear { i() }
		blocksScheduledForViewWillAppear = []
		super.viewWillAppear(animated)
		viewDidDisappearRetainedObjects += [KVOBinding(self•{$0.regeneratedChildContainers}, options: .Initial) { [unowned self] change in
			$(•change!)
			self.childContainers = self.regeneratedChildContainers
			self.tableView.reloadData()
		}]
		viewDidDisappearRetainedObjects += [KVOBinding(self•{$0.foldersController.foldersUpdateStateRaw}, options: .Initial) { [unowned self] change in
			assert(NSThread.isMainThread())
			(change)
			let foldersUpdateState = self.foldersController.foldersUpdateState
			let message: String = {
				switch foldersUpdateState {
				case .Completed:
					let foldersController = self.foldersController
					if let foldersUpdateError = foldersController.foldersLastUpdateError {
						return "\(foldersUpdateError)"
					}
					else if let foldersLastUpdateDate = foldersController.foldersLastUpdateDate {
						let loadAgo = loadAgoDateComponentsFormatter.stringFromDate(foldersLastUpdateDate, toDate: NSDate())!
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
		}]
	}
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		viewDidDisappearRetainedObjects = []
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		blocksScheduledForViewWillAppear += [{
			if nil != self.rootFolder?.parentFolder {
				self.title = self.rootFolder!.visibleTitle
			}
		}]
	}
	// MARK: -
	deinit {
		$(self)
	}
}

extension FoldersListTableViewController {
	func presentMessage(text: String) {
		statusLabel.text = (text)
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
