//
//  ItemsListViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

class ItemsListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	var streamID: NSString!
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: Item.entityName())
			$.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
			$.predicate = NSPredicate(format: "streamID == %@", argumentArray: [self.streamID])
			return $
		}()
		let cacheName = "Cache-StreamID:\(self.streamID)"
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: cacheName)
		$.delegate = self
		return $
	}()
	@IBAction func refresh(sender: AnyObject!) {
		rssSession.streamContents(self.streamID) { (streamError: NSError?) -> Void in
			trace("streamError", streamError)
			let refreshControl = sender as UIRefreshControl
			refreshControl.endRefreshing()
		}
	}
	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let item = fetchedResultsController.fetchedObjects![indexPath.row] as Item
		cell.textLabel?.text = item.title ?? item.id.lastPathComponent
	}
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
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.fetchedObjects!.count
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Item", forIndexPath: indexPath) as UITableViewCell
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "show" {
			let itemSummaryViewController = segue.destinationViewController as ItemSummaryViewController
			itemSummaryViewController.item = {
				let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
				let $ = self.fetchedResultsController.fetchedObjects![indexPathForSelectedRow.row] as Item
				return $
			}()
		}
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		var fetchError: NSError?
		fetchedResultsController.performFetch(&fetchError)
	}
}
