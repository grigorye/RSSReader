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
	typealias _Self = HistoryViewController
	private var nowDate: Date!
	static let fetchRequest = Item.fetchRequestForEntity() … {
		$0.sortDescriptors = [SortDescriptor(key: #keyPath(Item.lastOpenedDate), ascending: false)]
		$0.predicate = Predicate(format: "\(#keyPath(Item.lastOpenedDate)) != nil", argumentArray: [])
	}
	static var fetchedResultsControllerDelegateAOKey: Void?
	lazy var fetchedResultsController: NSFetchedResultsController<Item> = {
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: _Self.fetchRequest, managedObjectContext: mainQueueManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		let configureCell = { [unowned self] cell, indexPath in
			self.configureCell(cell, atIndexPath: indexPath)
		}
		let $ = TableViewFetchedResultsControllerDelegate(tableView: self.tableView, updateCell: configureCell)
		objc_setAssociatedObject(fetchedResultsController, &fetchedResultsControllerDelegateAOKey, $, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		fetchedResultsController.delegate = $
		return fetchedResultsController
	}()
	// MARK: -
	func itemForIndexPath(_ indexPath: NSIndexPath) -> Item {
		return self.fetchedResultsController.fetchedObjects![indexPath.row] 
	}
	var selectedItem: Item {
		return self.itemForIndexPath(tableView.indexPathForSelectedRow!)
	}
	// MARK: -
	func configureCell(_ rawCell: UITableViewCell, atIndexPath indexPath: IndexPath) {
		let cell = rawCell as! ItemTableViewCell
		let item = fetchedResultsController.object(at: indexPath) 
		if let titleLabel = cell.titleLabel {
			titleLabel.text = item.title ?? (item.id as NSString).lastPathComponent
		}
		if let dateLabel = cell.dateLabel {
			let timeIntervalFormatted = dateComponentsFormatter.string(from: item.date, to: nowDate)!
			dateLabel.text = timeIntervalFormatted.uppercased()
		}
		if let sourceLabel = cell.sourceLabel {
			sourceLabel.text = item.subscription.title.uppercased()
		}
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if defaults.pageViewsEnabled {
			self.performSegue(withIdentifier: MainStoryboard.SegueIdentifiers.ShowHistoryPages, sender: self)
		}
		else {
			self.performSegue(withIdentifier: MainStoryboard.SegueIdentifiers.ShowHistoryArticle, sender: self)
		}
	}
	// MARK: -
	override func numberOfSections(in tableView: UITableView) -> Int {
		return fetchedResultsController.sections!.count
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fetchedResultsController.sections![section].numberOfObjects
	}
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return fetchedResultsController.sections![section].name
	}
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath)
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case MainStoryboard.SegueIdentifiers.ShowHistoryPages:
			let pageViewController = segue.destinationViewController as! UIPageViewController
			let itemsPageViewControllerDataSource = (pageViewController.dataSource as! ItemsPageViewControllerDataSource) … {
				$0.items = self.fetchedResultsController.fetchedObjects!
			}
			let initialViewController = itemsPageViewControllerDataSource.viewControllerForItem(self.selectedItem, storyboard: pageViewController.storyboard!)
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				pageViewController.edgesForExtendedLayout = UIRectEdge()
			}
			pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
		case MainStoryboard.SegueIdentifiers.ShowHistoryArticle:
			let itemViewController = segue.destinationViewController as! ItemSummaryWebViewController
			itemViewController.item = selectedItem
			$(segue)
		default:
			abort()
		}
	}
	// MARK: -
	override func viewWillAppear(_ animated: Bool) {
		nowDate = Date()
		super.viewWillAppear(animated)
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		let cellNib = UINib(nibName: "ItemTableViewCell", bundle: nil)
		tableView.register(cellNib, forCellReuseIdentifier: "Item")
		try! fetchedResultsController.performFetch()
    }
	// MARK: -
	deinit {
		$(self)
	}
}
