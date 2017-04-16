//
//  HistoryViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import class GEUIKit.TableViewFetchedResultsControllerDelegate
import UIKit.UITableViewController
import CoreData.NSFetchedResultsController

extension TypedUserDefaults {
	@NSManaged var pageViewsEnabled: Bool
}

class HistoryViewController: UITableViewController {
	typealias _Self = HistoryViewController
	private var nowDate: Date!
	static let fetchRequest = Item.fetchRequestForEntity() … {
		$0.sortDescriptors = [NSSortDescriptor(key: #keyPath(Item.lastOpenedDate), ascending: false)]
		$0.predicate = NSPredicate(format: "\(#keyPath(Item.lastOpenedDate)) != nil", argumentArray: [])
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
	func itemForIndexPath(_ indexPath: IndexPath) -> Item {
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
			titleLabel.text = item.title /*?? (item.id as NSString).lastPathComponent*/
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
			self.performSegue(withIdentifier: R.segue.historyViewController.showHistoryPages, sender: self)
		}
		else {
			self.performSegue(withIdentifier: R.segue.historyViewController.showHistoryArticle, sender: self)
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
		let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.item, for: indexPath)!
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}
	// MARK: -
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier! {
		case R.segue.historyViewController.showHistoryPages.identifier:
			let pageViewController = segue.destination as! UIPageViewController
			let itemPageViewControllerDataSource = (pageViewController.dataSource as! ItemPageViewControllerDataSource) … {
				$0.items = self.fetchedResultsController.fetchedObjects!
			}
			let initialViewController = itemPageViewControllerDataSource.viewControllerForItem(self.selectedItem)
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				pageViewController.edgesForExtendedLayout = UIRectEdge()
			}
			pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
		case R.segue.historyViewController.showHistoryArticle.identifier:
			let itemViewController = segue.destination as! ItemSummaryWebViewController
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
		tableView.register(R.nib.itemTableViewCell)
		try! fetchedResultsController.performFetch()
    }
	// MARK: -
	deinit {
		$(self)
	}
}
