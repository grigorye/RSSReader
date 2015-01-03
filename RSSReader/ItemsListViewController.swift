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
	var continuation: NSString?
	var loadInProgress = false
	var loadCompleted = false
	var loadError: NSError?
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
	func loadMore(completionHandler: () -> Void) {
		assert(!loadInProgress, "")
		assert(nil == loadError, "")
		loadInProgress = true
		rssSession.streamContents(self.streamID, continuation: self.continuation) { (continuation: NSString?, streamError: NSError?) -> Void in
			dispatch_async(dispatch_get_main_queue()) {
				if let streamError = streamError {
					self.loadError = trace("streamError", streamError)
				}
				else {
					self.continuation = continuation
					if nil == continuation {
						self.loadCompleted = true
					}
				}
				self.loadInProgress = false
				completionHandler()
				self.loadMoreIfNecessary()
			}
		}
	}
	func loadMoreIfNecessary() {
		if !loadInProgress {
			if !loadCompleted {
				if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows() {
					if let lastIndexPath = indexPathsForVisibleRows.last as NSIndexPath? {
						if tableView.numberOfRowsInSection(0) - lastIndexPath.row < 10 {
							self.loadMore {}
						}
					}
				}
			}
		}
	}
	@IBAction func refresh(sender: AnyObject!) {
		if loadInProgress && trace("nil == continuation", nil == continuation) {
			self.refreshControl?.endRefreshing()
		}
		else {
			self.loadCompleted = false
			self.continuation = nil
			self.loadInProgress = false
			self.loadMore {
				void(self.refreshControl?.endRefreshing())
			}
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
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		trace("tableView.contentOffset", tableView.contentOffset)
		self.loadMoreIfNecessary()
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
