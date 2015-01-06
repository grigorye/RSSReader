//
//  SubscriptionsListViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

class SubscriptionsListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	var category: Folder?
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: Subscription.entityName())
			$.sortDescriptors = Subscription.sortDescriptorsVariants()[0]
			if let category = self.category {
				$.predicate = NSPredicate(format: "categories CONTAINS %@", argumentArray: [category])
			}
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		$.delegate = self
		return $
	}()
	// MARK: -
	@IBAction func refresh(sender: AnyObject!) {
		rssSession.updateSubscriptions { (error: NSError?) -> Void in
			let refreshControl = sender as UIRefreshControl
			refreshControl.endRefreshing()
		}
	}
	// MARK: -
	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let subscription = fetchedResultsController.fetchedObjects![indexPath.row] as Subscription
		cell.textLabel?.text = subscription.title ?? subscription.url?.lastPathComponent
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
			let indexPath = indexPath!
			if let cell = tableView.cellForRowAtIndexPath(indexPath) {
				self.configureCell(cell, atIndexPath: indexPath)
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
			let itemsListViewController = segue.destinationViewController as ItemsListViewController
			let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
			let subscription = fetchedResultsController.fetchedObjects![indexPathForSelectedRow.row] as Subscription
			itemsListViewController.title = subscription.title
			itemsListViewController.streamID = subscription.id
		}
	}
	// MARK: -
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.fetchedObjects!.count
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Subscription", forIndexPath: indexPath) as UITableViewCell
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

