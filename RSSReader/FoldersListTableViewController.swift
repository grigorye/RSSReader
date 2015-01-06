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
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: Folder.entityName())
			$.sortDescriptors = Folder.sortDescriptors()[0]
			$.predicate = NSPredicate(format: "id MATCHES 'user/.*label.*'", argumentArray: [])
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		$.delegate = self
		return $
	}()
	// MARK: -
	@IBAction func refresh(sender: AnyObject!) {
		rssSession.updateUnreadCounts { (error: NSError?) -> Void in
			let refreshControl = sender as UIRefreshControl
			refreshControl.endRefreshing()
		}
	}
	// MARK: -
	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let folder = fetchedResultsController.fetchedObjects![indexPath.row] as Folder
		cell.textLabel?.text = folder.id.lastPathComponent
	}
	// MARK: -
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		self.tableView.beginUpdates()
	}
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		let tableView = self.tableView!
 
		switch type {
		case .Insert:
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
		case .Delete:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation:UITableViewRowAnimation.Fade)
		case .Update:
			if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
				self.configureCell(cell, atIndexPath: indexPath!)
			}
		case .Move:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation:UITableViewRowAnimation.Fade)
		}
	}
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.endUpdates()
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "show" {
			let subscriptionsListViewController = segue.destinationViewController as SubscriptionsListViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
			let folder = fetchedResultsController.fetchedObjects![indexPathForSelectedRow.row] as Folder
			subscriptionsListViewController.title = folder.id.lastPathComponent
			subscriptionsListViewController.category = folder
		}
	}
	// MARK: -
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.fetchedObjects!.count
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Folder", forIndexPath: indexPath) as UITableViewCell
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		var fetchError: NSError?
		fetchedResultsController.performFetch(&fetchError)
	}
}
