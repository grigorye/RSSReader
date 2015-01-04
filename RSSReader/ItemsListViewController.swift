//
//  ItemsListViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

var dateComponentsFormatter: NSDateComponentsFormatter = {
	let $ = NSDateComponentsFormatter()
	$.unitsStyle = .Abbreviated
	$.allowsFractionalUnits = true
	$.maximumUnitCount = 1
	$.allowedUnits = .CalendarUnitMinute | .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitWeekOfMonth | .CalendarUnitDay | .CalendarUnitHour
	return $;
}()

class ItemsListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	var streamID: NSString!
	var continuation: NSString?
	lazy var loadDate = NSDate()
	var loadInProgress = false
	var lastLoadedItem: Item?
	var loadCompleted = false
	var loadError: NSError?
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: Item.entityName())
			$.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
			let streamIDInItems: NSString = {
				let id = self.streamID as NSString
				let url = NSURL(string: id)
				if let query = url?.query as NSString? {
					assert(id.hasSuffix(query), "")
					return id.substringToIndex(id.length - query.length - 1)
				}
				return id
			}()
			$.predicate = NSPredicate(format: "streamID == %@", argumentArray: [streamIDInItems])
			return $
		}()
		let cacheName = "Cache-StreamID:\(self.streamID)"
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: cacheName)
		$.delegate = self
		return $
	}()
	// MARK: -
	func loadMore(completionHandler: () -> Void) {
		assert(!loadInProgress, "")
		assert(nil == loadError, "")
		loadInProgress = true
		rssSession.streamContents(self.streamID, continuation: self.continuation, loadDate: self.loadDate) { (continuation: NSString?, items: [Item]!, streamError: NSError?) -> Void in
			dispatch_async(dispatch_get_main_queue()) {
				if let streamError = streamError {
					self.loadError = trace("streamError", streamError)
				}
				else {
					if let lastItemInCompletion = items.last {
						let managedObjectContext = self.fetchedResultsController.managedObjectContext
						self.lastLoadedItem = (managedObjectContext.objectWithID(lastItemInCompletion.objectID) as Item)
					}
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
					if let lastVisibleIndexPath = indexPathsForVisibleRows.last as NSIndexPath? {
						let numberOfRows = tableView.numberOfRowsInSection(0)
						let numberOfItemsToPreload = 10
						let barrierRow = lastVisibleIndexPath.row + numberOfItemsToPreload
						let indexOfLastLoadedItem = (nil == self.lastLoadedItem) ? 0 : (self.fetchedResultsController.fetchedObjects! as NSArray).indexOfObjectIdenticalTo(self.lastLoadedItem!)
						if indexOfLastLoadedItem < barrierRow {
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
			self.loadError = nil
			self.loadMore {
				void(self.refreshControl?.endRefreshing())
			}
		}
	}
	// MARK: -
	func selectedItem() -> Item {
		let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()!
		let $ = self.fetchedResultsController.fetchedObjects![indexPathForSelectedRow.row] as Item
		return $
	}
	
	// MARK: -
	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let item = fetchedResultsController.fetchedObjects![indexPath.row] as Item
		cell.textLabel?.text = item.title ?? item.id.lastPathComponent
		let timeIntervalFormatted = dateComponentsFormatter.stringFromDate(item.date, toDate: loadDate) ?? ""
		cell.detailTextLabel?.text = "\(timeIntervalFormatted)"
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
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.fetchedObjects!.count
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Item", forIndexPath: indexPath) as UITableViewCell
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		trace("tableView.contentOffset", tableView.contentOffset)
		self.loadMoreIfNecessary()
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showWeb" {
			let itemSummaryWebViewController = segue.destinationViewController as ItemSummaryWebViewController
			itemSummaryWebViewController.item = self.selectedItem()
		}
		else if segue.identifier == "showText" {
			let itemSummaryTextViewController = segue.destinationViewController as ItemSummaryTextViewController
			itemSummaryTextViewController.item = self.selectedItem()
		}
	}
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.loadDate = NSDate()
		self.tableView.reloadData()
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		var fetchError: NSError?
		fetchedResultsController.performFetch(&fetchError)
	}
}
