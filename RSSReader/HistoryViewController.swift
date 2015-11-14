//
//  HistoryViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import UIKit.UITableViewController
import CoreData.NSFetchedResultsController

class HistoryViewController: UITableViewController {
	private var nowDate: NSDate!
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest: NSFetchRequest = {
			let E = Item.self
			let $ = NSFetchRequest(entityName: E.entityName())
			let lastOpenedDateKeyPath = E••{"lastOpenedDate"}
			$.sortDescriptors = [NSSortDescriptor(key: lastOpenedDateKeyPath, ascending: false)]
			$.predicate = NSPredicate(format: "\(lastOpenedDateKeyPath) != nil", argumentArray: [])
			return $
		}()
		let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		$.retainedDelegate = TableViewFetchedResultsControllerDelegate(tableView: self.tableView, fetchedResultsController: $, configureCell: self.configureCell)
		return $
	}()
	// MARK: -
	func itemForIndexPath(indexPath: NSIndexPath) -> Item {
		return self.fetchedResultsController.fetchedObjects![indexPath.row] as! Item
	}
	var selectedItem: Item {
		return self.itemForIndexPath(self.tableView.indexPathForSelectedRow!)
	}
	// MARK: -
	func configureCell(rawCell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let cell = rawCell as! ItemTableViewCell
		let item = fetchedResultsController.objectAtIndexPath(indexPath) as! Item
		if let titleLabel = cell.titleLabel {
			titleLabel.text = item.title ?? (item.itemID as NSString).lastPathComponent
		}
		if let subtitleLabel = cell.subtitleLabel {
			let timeIntervalFormatted = (nil == NSClassFromString("NSDateComponentsFormatter")) ? "x" : dateComponentsFormatter.stringFromDate(item.date, toDate: nowDate) ?? ""
			subtitleLabel.text = "\(timeIntervalFormatted)"
		}
	}
	// MARK: -
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if defaults.pageViewsEnabled {
			self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.ShowHistoryPages, sender: self)
		}
		else {
			self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.ShowHistoryArticle, sender: self)
		}
	}
	// MARK: -
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return fetchedResultsController.sections!.count
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.sections![section].numberOfObjects
	}
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return fetchedResultsController.sections![section].name
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.ReuseIdentifiers.HistoryItem, forIndexPath: indexPath)
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowHistoryPages:
			let pageViewController = segue.destinationViewController as! UIPageViewController
			let itemsPageViewControllerDataSource: ItemsPageViewControllerDataSource = {
				let $ = pageViewController.dataSource as! ItemsPageViewControllerDataSource
				$.items = self.fetchedResultsController.fetchedObjects as! [Item]
				return $
			}()
			let initialViewController = itemsPageViewControllerDataSource.viewControllerForItem(self.selectedItem, storyboard: pageViewController.storyboard!)
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				pageViewController.edgesForExtendedLayout = .None
			}
			pageViewController.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
		case MainStoryboard.SegueIdentifiers.ShowHistoryArticle:
			let itemViewController = segue.destinationViewController as! ItemSummaryWebViewController
			itemViewController.item = selectedItem
			$(segue).$()
		default:
			abort()
		}
	}
	// MARK: -
	override func viewWillAppear(animated: Bool) {
		nowDate = NSDate()
		super.viewWillAppear(animated)
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		try! fetchedResultsController.performFetch()
    }
}
