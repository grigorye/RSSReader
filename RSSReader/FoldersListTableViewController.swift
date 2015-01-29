//
//  FoldersListTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 06.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

class FoldersListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	dynamic var rootFolder: Folder!
	var childContainers: [Container]!
	let defaults = KVOCompliantUserDefaults()
	class func keyPathsForValuesAffectingRegeneratedChildContainers() -> NSSet {
		return NSSet(array: ["defaults.showUnreadOnly", "rootFolder.childContainers"])
	}
	var regeneratedChildContainers: [Container] {
		if let rootFolder = rootFolder {
			let showUnreadOnly = defaults.showUnreadOnly
			return (rootFolder.childContainers.array as [Container]).filter { showUnreadOnly ? $0.unreadCount > 0 : true }
		}
		else {
			return []
		}
	}
	// MARK: -
	@IBAction func refresh(sender: AnyObject!) {
		rssSession.updateUnreadCounts { error in
			dispatch_async(dispatch_get_main_queue()) {
				if nil == self.rootFolder {
					self.rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: self.mainQueueManagedObjectContext)
				}
				self.tableView.reloadData()
				let refreshControl = sender as UIRefreshControl
				refreshControl.endRefreshing()
			}
		}
	}
	// MARK: -
	func configureCell(cell: UITableViewCell, forFolder folder: Folder) {
		(cell as TableViewContainerCell).setFromContainer(folder)
		cell.textLabel?.text = folder.id.lastPathComponent
	}
	func configureCell(cell: UITableViewCell, forSubscription subscription: Subscription) {
		(cell as TableViewContainerCell).setFromContainer(subscription)
		cell.textLabel?.text = subscription.title ?? subscription.url?.lastPathComponent
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch SegueIdentifier(rawValue: segue.identifier!)!  {
		case .showFolder:
			let foldersListTableViewController = segue.destinationViewController as FoldersListTableViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
			let folder = childContainers[indexPathForSelectedRow.row] as Folder
			foldersListTableViewController.title = folder.id.lastPathComponent
			foldersListTableViewController.rootFolder = folder
		case .showSubscription:
			let itemsListViewController = segue.destinationViewController as ItemsListViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
			let subscription = childContainers[indexPathForSelectedRow.row] as Subscription
			itemsListViewController.title = subscription.title
			itemsListViewController.folder = subscription
		default:
			abort()
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
			let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReuseIdentifier.Subscription.rawValue, forIndexPath: indexPath) as UITableViewCell
			self.configureCell(cell, forSubscription: subscription)
			return cell
		case let folder as Folder:
			let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReuseIdentifier.Folder.rawValue, forIndexPath: indexPath) as UITableViewCell
			self.configureCell(cell, forFolder: folder)
			return cell
		default:
			abort()
		}
	}
	// MARK: -
	var viewDidDisappearRetainedObjects = [AnyObject]()
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		viewDidDisappearRetainedObjects += [KVOBinding(object: self, keyPath: "regeneratedChildContainers", options: .Initial) { [unowned self] _ in
			self.childContainers = self.regeneratedChildContainers
			self.tableView.reloadData()
		}]
	}
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		viewDidDisappearRetainedObjects = []
	}
}
