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
	var loadDate: NSDate!
	var loadInProgress = false
	var lastLoadedItem: Item?
	var loadCompleted = false
	var loadError: NSError?
	var tableFooterView: UIView?
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let $ = NSFetchRequest(entityName: Item.entityName())
			$.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
			$.predicate = NSPredicate(format: "streamID == %@", argumentArray: [self.streamID])
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		$.delegate = self
		return $
	}()
	// MARK: -
	func loadMore(completionHandler: (loadDateDidChange: Bool) -> Void) {
		assert(!loadInProgress, "")
		assert(!loadCompleted, "")
		assert(nil == loadError, "")
		if nil == self.continuation {
			self.loadDate = NSDate()
		}
		let loadDate = self.loadDate
		loadInProgress = true
		rssSession.streamContents(self.streamID, continuation: self.continuation, loadDate: self.loadDate) { (continuation: NSString?, items: [Item]!, streamError: NSError?) -> Void in
			dispatch_async(dispatch_get_main_queue()) {
				if loadDate != self.loadDate {
					// Ignore results from previous sessions.
					completionHandler(loadDateDidChange: true)
					return
				}
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
						UIView.animateWithDuration(0.4) {
							self.tableView.tableFooterView = nil
						}
					}
				}
				self.loadInProgress = false
				completionHandler(loadDateDidChange: false)
				self.loadMoreIfNecessary()
			}
		}
	}
	func loadMoreIfNecessary() {
		if !loadInProgress {
			if !loadCompleted {
				if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows() {
					let shouldLoadMore: Bool = {
						if let lastVisibleIndexPath = indexPathsForVisibleRows.last as NSIndexPath? {
							let numberOfRows = self.tableView.numberOfRowsInSection(0)
							let numberOfItemsToPreload = 10
							let barrierRow = lastVisibleIndexPath.row + numberOfItemsToPreload
							let indexOfLastLoadedItem = (nil == self.lastLoadedItem) ? 0 : (self.fetchedResultsController.fetchedObjects! as NSArray).indexOfObjectIdenticalTo(self.lastLoadedItem!)
							return indexOfLastLoadedItem < barrierRow
						}
						return true
					}()
					if shouldLoadMore {
						self.loadMore { loadDateDidChange in
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
			self.loadMore { loadDateDidChange in
				if !loadDateDidChange {
					void(self.refreshControl?.endRefreshing())
				}
			}
			UIView.animateWithDuration(0.4) {
				self.tableView.tableFooterView = self.tableFooterView
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
		self.tableView.reloadData()
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		var fetchError: NSError?
		fetchedResultsController.performFetch(&fetchError)
		assert(nil == fetchError, "")
		self.tableFooterView = tableView.tableFooterView
	}
}
