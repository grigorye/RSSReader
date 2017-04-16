//
//  ContainerViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 15/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

extension TypedUserDefaults {
	@NSManaged var showAllItemsCount: Bool
}

class ContainerViewController: UITableViewController {
	dynamic var container: Container!
	dynamic var predicateForItems: NSPredicate? {
		return container?.predicateForItems
	}
	// MARK: -
	dynamic var itemsCount = 0
	private var currentItemsFetchedObjectCountBinding: FetchedObjectCountBinding<Item>?
	func bindItemsCount() -> Handler {
		let binding = KVOBinding(self•#keyPath(predicateForItems), options: [.initial, .new]) { _ in
			let predicate = self.predicateForItems
			let itemsFetchedObjectCountBinding = FetchedObjectCountBinding<Item>(managedObjectContext: mainQueueManagedObjectContext, predicate: predicate) {
				count in
				self.itemsCount = count
			}
			self.currentItemsFetchedObjectCountBinding = itemsFetchedObjectCountBinding
		}
		return {
			_ = binding
			self.currentItemsFetchedObjectCountBinding = nil
		}
	}
	// MARK: -
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! ContainerTableViewSectionHeaderView
		sectionHeaderView.titleLabel.text = (self.container as! Titled?)?.visibleTitle
		return sectionHeaderView
	}
	// MARK: -
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		$(container)
		if defaults.showAllItemsCount {
			scheduledForViewDidDisappear += [bindItemsCount()]
		}
	}
	private var scheduledForViewDidDisappear = ScheduledHandlers()
	override func viewDidDisappear(_ animated: Bool) {
		scheduledForViewDidDisappear.perform ()
		super.viewDidDisappear(animated)
	}
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(R.nib.containerTableViewSectionHeader(), forHeaderFooterViewReuseIdentifier: "SectionHeader")
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 44
	}
}
