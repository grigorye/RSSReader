 //
//  ItemTableViewDataSource.swift
//  RSSReader
//
//  Created by Grigory Entin on 25/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEUIKit
import GEFoundation
import GETracing
import CoreData
import UIKit

extension KVOCompliantUserDefaults {
	@NSManaged var frequencyAndWeightBasedTableRowHeightEstimatorEnabled: Bool
	@NSManaged var cellHeightCachingEnabled: Bool
	@NSManaged var fixedHeightItemRowsEnabled: Bool
	@NSManaged var fetchBatchSize: Int
}

extension KVOCompliantUserDefaults {
	@NSManaged public var itemsAreSortedByLoadDate: Bool
}

class ItemTableViewDataSource: NSObject {
	var systemLayoutSizeCachingDataSource = SystemLayoutSizeCachingTableViewCellDataSource(
		layoutSizeDefiningValueForCell: {
			guard $0.reuseIdentifier != "Item" else {
				return nil
			}
			return $0.reuseIdentifier as NSString?
		},
		cellShouldBeReusedWithoutLayout: {
			return $0.reuseIdentifier != "Item"
		}
	)
	weak var tableView: UITableView?
	let container: Container
	let showUnreadOnly: Bool
	fileprivate let nowDate = { Date() }()
	var heightSampleLabel: UILabel!
	var cachedVariableHeights: [NSManagedObjectID : CGFloat] = [:]
	lazy var containerViewPredicate: NSPredicate = {
		if self.showUnreadOnly {
			return NSPredicate(format: "SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}()
	// MARK: -
	private class var keyPathsForValuesAffectingPredicateForItems: Set<String> {
		return [#keyPath(fetchedResultsController)]
	}
	private dynamic var predicateForItems: NSPredicate {
		return fetchedResultsController.fetchRequest.predicate!
	}
	// MARK: -
	private lazy var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate = {
		let tableView = self.tableView!
		let configureCell = { [unowned self] (cell: UITableViewCell, indexPath: IndexPath) -> Void in
			self.configureCell(cell, atIndexPath: indexPath)
		}
		return TableViewFetchedResultsControllerDelegate(tableView: tableView, updateCell: configureCell)
	}()
	lazy private dynamic var fetchedResultsController: NSFetchedResultsController<Item> = {
		typealias E = Item
		let fetchRequest = E.fetchRequestForEntity() … {
			$0.sortDescriptors = sortDescriptorsForContainers
			$0.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[NSPredicate]() … { (x: inout [NSPredicate]) in
				x += [self.container.predicateForItems]
				x += [self.containerViewPredicate]
			})
#if true
			$0.relationshipKeyPathsForPrefetching = [
				#keyPath(E.categories)
			]
#endif
			$0.returnsObjectsAsFaults = false
			$0.fetchBatchSize = defaults.fetchBatchSize
#if false
			$0.propertiesToFetch = [
				#keyPath(E.titleData)
			]
#endif
		}
		return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainQueueManagedObjectContext, sectionNameKeyPath: !defaults.itemsAreSortedByLoadDate ? nil : #keyPath(Item.loadDate), cacheName: nil)…{
			$0.delegate = self.fetchedResultsControllerDelegate
		}
	}()
	// MARK: -
	func performFetch() throws {
		try fetchedResultsController.performFetch()
	}
	func object(at indexPath: IndexPath) -> Item {
		return fetchedResultsController.object(at: indexPath)
	}
	func numberOfObjects(inSection section: Int) -> Int {
		return fetchedResultsController.sections![section].numberOfObjects
	}
	func indexPath(forObject object: Item) -> IndexPath? {
		return fetchedResultsController.indexPath(forObject: object)
	}
	var fetchedObjects: [Item]? {
		return fetchedResultsController.fetchedObjects
	}
	var sections: [NSFetchedResultsSectionInfo]? {
		return fetchedResultsController.sections
	}
	//
	lazy var rowHeightEstimator: FrequencyAndWeightBasedTableRowHeightEstimator<ItemTableViewDataSource>! = {
		guard defaults.frequencyAndWeightBasedTableRowHeightEstimatorEnabled else {
			return nil
		}
		return FrequencyAndWeightBasedTableRowHeightEstimator(dataSource: self)
	}()
	fileprivate var reusedCellGenerator: TableViewHeightBasedReusedCellGenerator<ItemTableViewDataSource>!
	//
	func configureCellHeightCaching() {
		guard let tableView = tableView else { return }
		let reuseIdentifiersForHeightCachingCells = (0...3).map {"Item-\($0)"}
		for (i, reuseIdentifier) in reuseIdentifiersForHeightCachingCells.enumerated() {
			let cellNib = UINib(nibName: "ItemTableViewCell-\(i)", bundle: nil)
			tableView.register(cellNib, forCellReuseIdentifier: reuseIdentifier)
		}
		reusedCellGenerator = TableViewHeightBasedReusedCellGenerator(dataSource: self, heightAgnosticCellReuseIdentifier: "Item", reuseIdentifiersForHeightCachingCells: reuseIdentifiersForHeightCachingCells)
	}
	func configureReusableCells() {
		guard let tableView = tableView else { return }
		guard !defaults.fixedHeightItemRowsEnabled else {
#if false
			let cellNib = UINib(nibName: "ItemSimpleTableViewCell", bundle: nil)
			tableView.register(cellNib, forCellReuseIdentifier: "Item")
#else
			tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Item")
#endif
			return
		}
		if defaults.cellHeightCachingEnabled {
			configureCellHeightCaching()
		}
		let cellNib = UINib(nibName: "ItemTableViewCell", bundle: nil)
		tableView.register(cellNib, forCellReuseIdentifier: "Item")
	}
	// MARK: -
	init(tableView: UITableView, container: Container, showUnreadOnly: Bool) {
		self.tableView = tableView
		self.container = container
		self.showUnreadOnly = showUnreadOnly
		super.init()
		self.configureReusableCells()
	}
}

// MARK: - UITableViewDataSource
extension ItemTableViewDataSource: UITableViewDataSource {
	func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
		let item = object(at: (indexPath))
		guard let cellDataBinder = cell as? ItemTableViewCellDataBinder else {
			cell.textLabel!.text = item.objectID.uriRepresentation().lastPathComponent
			return
		}
		cellDataBinder.setData((item: item, container: self.container, nowDate: nowDate))
	}
	// MARK: - 
	func numberOfSections(in tableView: UITableView) -> Int {
		let numberOfSections = sections?.count ?? 0
		return (numberOfSections)
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let dt = disableTrace(); defer { _ = dt }
		let numberOfRows = $(numberOfObjects(inSection: section))
		return $(numberOfRows)
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let dt = disableTrace(); defer { _ = dt }
		let reuseIdentifier = reusedCellGenerator?.reuseIdentifierForCellForRowAtIndexPath(indexPath) ?? "Item"
		let cell = tableView.dequeueReusableCell(withIdentifier: $(reuseIdentifier), for: indexPath)
#if true
		if let cell = cell as? ItemTableViewCell, nil != reusedCellGenerator {
			cell.systemLayoutSizeCachingDataSource = systemLayoutSizeCachingDataSource
		}
#endif
		configureCell(cell, atIndexPath: $(indexPath))
		return cell
	}
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		precondition(tableView == self.tableView)
		guard defaults.itemsAreSortedByLoadDate else {
			return nil
		}
		let sectionName = sections![section].name
		let dateForDisplay: Date? = Date(timeIntervalSinceReferenceDate: (sectionName as NSString).doubleValue)
		let title: String = {
			if let loadDate = dateForDisplay {
				let loadAgo = loadAgoLongDateComponentsFormatter.string(from: loadDate, to: nowDate)
				return String.localizedStringWithFormat(NSLocalizedString("%@ ago", comment: ""), loadAgo!)
			}
			else {
				return NSLocalizedString("Just now", comment: "")
			}
		}()
		return _0 ? nil : title
	}
}

// MARK: - UITableViewDataSourcePrefetching
extension ItemsViewController: UITableViewDataSourcePrefetching {
	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
		let objectIDs = $(indexPaths).map { dataSource.object(at: $0).objectID }
		let fetchRequest = Item.fetchRequestForEntity() … {
			$0.predicate = NSPredicate(format: "self in %@", objectIDs)
			$0.returnsObjectsAsFaults = false
		}
		_ = try! mainQueueManagedObjectContext.fetch(fetchRequest)
	}
}

// MARK: - UIDataSourceModelAssociation
extension ItemsViewController: UIDataSourceModelAssociation {
    func modelIdentifierForElement(at indexPath: IndexPath, in view: UIView) -> String? {
		if let item = itemForIndexPath(indexPath) {
			return item.objectID.uriRepresentation().absoluteString
		}
		else {
			let invalidModelIdentifier = ""
			return $(invalidModelIdentifier)
		}
	}
    func indexPathForElement(withModelIdentifier identifier: String, in view: UIView) -> IndexPath? {
		let objectIDURL = URL(string: identifier)!
		let managedObjectContext = mainQueueManagedObjectContext
		let objectID = managedObjectContext.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: objectIDURL)!
		let object = managedObjectContext.object(with: objectID) as! Item
		guard let indexPath = dataSource.indexPath(forObject: object) else {
			$(object)
			$($(dataSource).fetchedObjects)
			return nil
		}
		return $(indexPath)
	}
}

// MARK: - TableViewHeightBasedReusedCellGeneratorDataSource
extension ItemTableViewDataSource : TableViewHeightBasedReusedCellGeneratorDataSource {
	func viewWithVariableHeightForCell(_ cell: UITableViewCell) -> UIView {
		let cell = cell as! ItemTableViewCell
		return cell.titleLabel
	}
	func variableHeight(forCell cell: UITableViewCell) -> CGFloat {
		return viewWithVariableHeightForCell(cell).bounds.height
	}
	func isReadyForMeasuringHeigthsForData() -> Bool {
		return nil != heightSampleLabel
	}
	func variableHeightForDataAtIndexPath(_ indexPath: IndexPath) -> CGFloat {
		let item = object(at: indexPath)
		let cacheKey = item.objectID
		if let cachedHeight = cachedVariableHeights[cacheKey] {
			return cachedHeight
		}
		heightSampleLabel.text = item.title
		let size = heightSampleLabel.sizeThatFits(CGSize(width: heightSampleLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
		let height = size.height
		cachedVariableHeights[cacheKey] = height
		return height
	}
	func addRowHeight(_ rowHeight: CGFloat, for cell: UITableViewCell, at indexPath: IndexPath) {
		if nil == heightSampleLabel {
			let viewWithVariableHeight = viewWithVariableHeightForCell(cell)
			heightSampleLabel = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: viewWithVariableHeight)) as! UILabel
		}
		if cell.reuseIdentifier! == reusedCellGenerator.heightAgnosticCellReuseIdentifier {
			reusedCellGenerator?.addRowHeight(rowHeight, forCell: cell, atIndexPath: indexPath)
		}
		rowHeightEstimator?.addRowHeight(rowHeight, forIndexPath: indexPath)
	}
}

// MARK: - FrequencyAndWeightBasedTableRowHeightEstimatorDataSource
extension ItemTableViewDataSource: FrequencyAndWeightBasedTableRowHeightEstimatorDataSource {
	func weightForHeightDefiningValue(atIndexPath indexPath: IndexPath) -> Int {
		let item = object(at: indexPath)
		let length = item.title.utf16.count
		return length
	}
}
