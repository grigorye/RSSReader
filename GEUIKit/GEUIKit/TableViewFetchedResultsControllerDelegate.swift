//
//  TableViewFetchedResultsControllerDelegate.swift
//  GEBase
//
//  Created by Grigory Entin on 12.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import func GECoreData.stringFromFetchedResultsChangeType
import CoreData.NSFetchedResultsController
import UIKit.UITableView

extension TypedUserDefaults {
	@NSManaged var fetchResultsAnimationEnabled: Bool
	@NSManaged var groupingTableUpdatesEnabled: Bool
	@NSManaged var updateCellsInPlaceEnabled: Bool
	@NSManaged var reloadDataForTableUpdatesEnabled: Bool
	@NSManaged var suppressInPlaceCellUpdates: Bool
	@NSManaged var fetchResultsDebugEnabled: Bool
}

private var fetchResultsAnimationEnabled: Bool {
	return defaults.fetchResultsAnimationEnabled
}

private var groupingTableUpdatesEnabled: Bool {
	return defaults.groupingTableUpdatesEnabled
}
private var reloadDataForTableUpdatesEnabled: Bool {
	return defaults.reloadDataForTableUpdatesEnabled
}

private struct Counts {
	var insertions: Int
	var deletions: Int
	var updates: Int
}
private let zeroCounts = Counts(insertions: 0, deletions: 0, updates: 0)

public class TableViewFetchedResultsControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
	weak var tableView: UITableView?
	var updateCell: (UITableViewCell, _ atIndexPath: IndexPath) -> Void
	let rowAnimation: UITableViewRowAnimation = .none
	private var counts = zeroCounts
	// MARK: -
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		x$(controller)
		if defaults.fetchResultsDebugEnabled  {
			let managedObjectContext = controller.managedObjectContext
			assert(managedObjectContext.concurrencyType == .mainQueueConcurrencyType)
			for updatedObject in managedObjectContext.updatedObjects {
				((updatedObject).changedValues())
			}
			•(managedObjectContext.insertedObjects)
		}
		guard !reloadDataForTableUpdatesEnabled else {
			tableView?.reloadData()
			return
		}
		if groupingTableUpdatesEnabled {
			(x$(fetchResultsAnimationEnabled) ? invoke : UIView.performWithoutAnimation) {
				guard let tableView = tableView else {
					return
				}
				x$(tableView).beginUpdates()
			}
		}
	}
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		guard !reloadDataForTableUpdatesEnabled else {
			return
		}
		guard let tableView = tableView else {
			return
		}
		x$(controller)
		x$(stringFromFetchedResultsChangeType(type))
		switch type {
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: rowAnimation)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: rowAnimation)
		default:
			abort()
		}
	}
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		guard !reloadDataForTableUpdatesEnabled else {
			return
		}
		guard let tableView = tableView else {
			return
		}
		x$(tableView)
		x$(controller)
		x$(stringFromFetchedResultsChangeType(type))
		switch type {
		case .insert:
			counts.insertions += 1
			if defaults.fetchResultsDebugEnabled{
				x$(tableView.numberOfRows(inSection: x$(newIndexPath!).section))
			}
			tableView.insertRows(at: [newIndexPath!], with: rowAnimation)
		case .delete:
			counts.deletions += 1
			tableView.deleteRows(at: [x$(indexPath!)], with: rowAnimation)
		case .update:
			counts.updates += 1
			if defaults.fetchResultsDebugEnabled {
				x$(tableView.numberOfRows(inSection: x$(indexPath!).section))
			}
			if defaults.updateCellsInPlaceEnabled {
				if !defaults.suppressInPlaceCellUpdates, let cell = tableView.cellForRow(at: indexPath!) {
					let indexPathForCell = tableView.indexPath(for: cell)!
					updateCell(cell, indexPathForCell)
				}
			}
			else {
				tableView.reloadRows(at: [indexPath!], with: rowAnimation)
			}
		case .move:
			tableView.deleteRows(at: [x$(indexPath!)], with: rowAnimation)
			tableView.insertRows(at: [x$(newIndexPath!)], with: rowAnimation)
		}
	}
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		guard !reloadDataForTableUpdatesEnabled else {
			return
		}
		x$(controller)
		x$(counts)
		counts = zeroCounts
		if groupingTableUpdatesEnabled {
			(x$(fetchResultsAnimationEnabled) ? invoke : UIView.performWithoutAnimation) {
				guard let tableView = tableView else {
					return
				}
				x$(tableView).endUpdates()
			}
		}
	}
	// MARK: -
	public init(tableView: UITableView, updateCell: @escaping (UITableViewCell, _ atIndexPath: IndexPath) -> Void) {
		self.tableView = tableView
		self.updateCell = updateCell
	}
}
