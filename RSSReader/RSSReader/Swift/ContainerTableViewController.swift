//
//  RSSContainerTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 15/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import Foundation

class ContainerTableViewController: UITableViewController {
	dynamic var container: Container!
	dynamic var predicateForItems: NSPredicate {
		return container!.predicateForItems
	}
	// MARK: -
	dynamic var itemsCount = 0
	private var currentItemsCountFetchedObjectsBinding: FetchedObjectBinding<Item>?
	func bindItemsCount() -> Handler {
		let binding = KVOBinding(self•#keyPath(predicateForItems), options: [.initial, .new]) { _ in
			let predicate = self.predicateForItems
			let itemsCountFetchedObjectBinding = FetchedObjectBinding<Item>(managedObjectContext: mainQueueManagedObjectContext, predicate: predicate) { objects in
				self.itemsCount = objects.count
			}
			self.currentItemsCountFetchedObjectsBinding = itemsCountFetchedObjectBinding
		}
		return {
			_ = binding
			self.currentItemsCountFetchedObjectsBinding = nil
		}
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! ContainerTableViewSectionHeaderView
		sectionHeaderView.titleLabel.text = (self.container as! Titled?)?.visibleTitle
		return sectionHeaderView
	}
	// MARK: -
	private var blocksDelayedTillViewDidDisappear = [Handler]()
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		blocksDelayedTillViewDidDisappear += [bindItemsCount()]
	}
	override func viewDidDisappear(_ animated: Bool) {
		blocksDelayedTillViewDidDisappear.forEach {$0()}
		blocksDelayedTillViewDidDisappear = []
		super.viewDidDisappear(animated)
	}
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UINib(nibName: "ContainerTableViewSectionHeader", bundle: self.nibBundle), forHeaderFooterViewReuseIdentifier: "SectionHeader")
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 44
	}
}
