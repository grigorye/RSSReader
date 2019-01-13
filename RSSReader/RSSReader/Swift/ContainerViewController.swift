//
//  ContainerViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 15/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GECoreData
import CoreData
import UIKit

extension TypedUserDefaults {
	@NSManaged var showAllItemsCount: Bool
}

extension TypedUserDefaults {
	@NSManaged var showContainerTitleInTableHeader: Bool
}

class ContainerViewController: UITableViewController {
	@objc dynamic var container: Container
	@objc dynamic var predicateForItems: NSPredicate? {
		return container.predicateForItems
	}
	// MARK: - State Preservation and Restoration
	private enum Restorable : String {
		case containerObjectID
		case showsContainerTitle
		case title // Should not be localized (but it is).
	}
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		container.encodeObjectIDWithCoder(coder, key: Restorable.containerObjectID.rawValue)
		coder.encode(showsContainerTitle, forKey: Restorable.showsContainerTitle.rawValue)
		coder.encode(title, forKey: Restorable.title.rawValue)
	}
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		container = NSManagedObjectContext.objectWithIDDecodedWithCoder(coder, key: Restorable.containerObjectID.rawValue, managedObjectContext: mainQueueManagedObjectContext) as! Container
		showsContainerTitle = coder.decodeBool(forKey: Restorable.showsContainerTitle.rawValue)
		title = {
			guard let title = coder.decodeObject(forKey: Restorable.title.rawValue) as? String else {
				//assert(false)
				return nil
			}
			return title
		}()
	}
	// MARK: -
	@objc dynamic var itemsCount = 0
	private var currentItemsFetchedObjectCountBinding: FetchedObjectCountBinding<Item>?
	func bindItemsCount() -> Handler {
		let binding = self.observe(\.predicateForItems, options: [.initial, .new]) { (_, _) in
			let predicate = self.predicateForItems
			let itemsFetchedObjectCountBinding = FetchedObjectCountBinding<Item>(managedObjectContext: mainQueueManagedObjectContext, predicate: predicate) { count in
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
		guard defaults.showContainerTitleInTableHeader else {
			return nil
		}
		let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! ContainerTableViewSectionHeaderView
		sectionHeaderView.titleLabel.text = (self.container as! Titled).visibleTitle
		return sectionHeaderView
	}
	// MARK: -
	private var scheduledForViewWillAppear = ScheduledHandlers()
	override func viewWillAppear(_ animated: Bool) {
		scheduledForViewWillAppear.perform()
		super.viewWillAppear(animated)
		x$(container)
		if defaults.showAllItemsCount {
			scheduledForViewDidDisappear += [bindItemsCount()]
		}
	}
	private var scheduledForViewDidDisappear = ScheduledHandlers()
	override func viewDidDisappear(_ animated: Bool) {
		scheduledForViewDidDisappear.perform()
		super.viewDidDisappear(animated)
	}
	
	var containerTitle: String? {
		return (container as! Titled).visibleTitle
	}

	var showsContainerTitle: Bool = true
	
	func updateViewForContainer() {
		if showsContainerTitle {
			navigationItem.title = containerTitle
		}
	}
	
	// MARK: -
	override func viewDidLoad() {
		super.viewDidLoad()
		if defaults.showContainerTitleInTableHeader {
			tableView.register(UINib(resource: R.nib.containerTableViewSectionHeader), forHeaderFooterViewReuseIdentifier: "SectionHeader")
			tableView.sectionHeaderHeight = UITableViewAutomaticDimension
			tableView.estimatedSectionHeaderHeight = 44
		} else {
			scheduledForViewWillAppear.append { [weak self] in
				self?.updateViewForContainer()
			}
			tableView.sectionHeaderHeight = 0
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.container = RSSReader.rootFolder() ?? RSSReader.fakeRootFolderInsertedAsNecessary()
		super.init(coder: aDecoder)
	}
}
