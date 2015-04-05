//
//  FoldersListTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 06.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

class FoldersListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation {
	dynamic var rootFolder: Folder?
	private var childContainers: [Container]!
	let defaults = KVOCompliantUserDefaults()
	class func keyPathsForValuesAffectingRegeneratedChildContainers() -> Set<String> {
		return ["defaults.showUnreadOnly", "rootFolder.childContainers"]
	}
	private var regeneratedChildContainers: [Container] {
		let regeneratedChildContainers: [Container] = {
			if let rootFolder = self.rootFolder {
				let showUnreadOnly = self.defaults.showUnreadOnly
				return (rootFolder.childContainers.array as! [Container]).filter { showUnreadOnly ? $0.unreadCount > 0 : true }
			}
			else {
				return []
			}
		}()
		return $(regeneratedChildContainers).$(0)
	}
	// MARK: -
	@IBAction func refresh(sender: AnyObject!) {
		rssSession!.updateAll { error in dispatch_async(dispatch_get_main_queue()) {
			if let error = error {
				self.presentErrorMessage(NSLocalizedString("Got a problem with feeds retrieval. \(error.localizedDescription)", comment: ""))
			}
			else {
				self.presentInfoMessage(NSLocalizedString("Feeds have been retrieved.", comment: ""))
			}
			if nil == error {
				if nil == self.rootFolder {
					self.rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: self.mainQueueManagedObjectContext)
					assert(nil != self.rootFolder)
				}
			}
			self.tableView.reloadData()
			let refreshControl = sender as! UIRefreshControl
			refreshControl.endRefreshing()
		}}
	}
	// MARK: -
	private func configureCell(cell: UITableViewCell, forFolder folder: Folder) {
		(cell as! TableViewContainerCell).setFromContainer(folder)
		cell.textLabel?.text = folder.streamID.lastPathComponent
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
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
			let folder = childContainers[indexPathForSelectedRow.row] as! Folder
			foldersListTableViewController.rootFolder = folder
		case MainStoryboard.SegueIdentifiers.ShowSubscription:
			let itemsListViewController = segue.destinationViewController as! ItemsListViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
			let subscription = childContainers[indexPathForSelectedRow.row] as! Subscription
			itemsListViewController.container = subscription
		default:
			abort()
		}
	}
	// MARK: -
    func modelIdentifierForElementAtIndexPath(indexPath: NSIndexPath, inView view: UIView) -> String {
		let childContainer = childContainers[indexPath.row]
		return childContainer.objectID.URIRepresentation().absoluteString!
	}
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
		let objectIDURL = NSURL(string: identifier)!
		if let row = find(childContainers.map { return $0.objectID.URIRepresentation().absoluteString! }, identifier) {
			let indexPath = NSIndexPath(forRow: row, inSection: 0)
			return $(indexPath).$()
		}
		else {
			let missingObjectIDURL = objectIDURL
			$(missingObjectIDURL).$()
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
			let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.ReuseIdentifiers.Subscription, forIndexPath: indexPath) as! UITableViewCell
			self.configureCell(cell, forSubscription: subscription)
			return cell
		case let folder as Folder:
			let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.ReuseIdentifiers.Folder, forIndexPath: indexPath) as! UITableViewCell
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
		if let rootFolder = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.rootFolderObjectID.rawValue, managedObjectContext: self.mainQueueManagedObjectContext) as! Folder? {
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
		viewDidDisappearRetainedObjects += [KVOBinding(object: self, keyPath: "regeneratedChildContainers", options: .Initial) { [unowned self] change in
			$(change).$(0)
			self.childContainers = self.regeneratedChildContainers
			self.tableView.reloadData()
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
}
