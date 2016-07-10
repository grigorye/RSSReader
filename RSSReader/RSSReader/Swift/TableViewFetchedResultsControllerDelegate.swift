//
//  TableViewFetchedResultsControllerDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData.NSFetchedResultsController
import UIKit.UITableView

private var fetchResultsAnimationEnabled: Bool {
	return defaults.fetchResultsAnimationEnabled
}

private var groupingTableUpdatesEnabled: Bool {
	return defaults.groupingTableUpdatesEnabled
}

class TableViewFetchedResultsControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
	var tableView: UITableView
	var updateCell: (UITableViewCell, atIndexPath: IndexPath) -> Void
	var rowAnimation: UITableViewRowAnimation { return .automatic }
	// MARK: -
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		$(controller)
		let managedObjectContext = controller.managedObjectContext
		assert(managedObjectContext.concurrencyType == .mainQueueConcurrencyType)
		for updatedObject in managedObjectContext.updatedObjects {
			((updatedObject).changedValues())
		}
		•(managedObjectContext.insertedObjects)
		if groupingTableUpdatesEnabled {
			($(fetchResultsAnimationEnabled) ? invoke : UIView.performWithoutAnimation) {
				$(self.tableView).beginUpdates()
			}
		}
	}
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		$(controller)
		$(stringFromFetchedResultsChangeType(type))
		switch type {
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: rowAnimation)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: rowAnimation)
		default:
			abort()
		}
	}
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		let tableView = self.tableView
		$(tableView)
		$(controller)
		$(stringFromFetchedResultsChangeType(type))
		switch type {
		case .insert:
			$(tableView.numberOfRows(inSection: $(newIndexPath!).section))
			tableView.insertRows(at: [newIndexPath!], with: rowAnimation)
		case .delete:
			tableView.deleteRows(at: [$(indexPath!)], with: rowAnimation)
		case .update:
			$(tableView.numberOfRows(inSection: $(indexPath!).section))
			if defaults.updateCellsInPlaceEnabled {
				if let cell = tableView.cellForRow(at: indexPath!) {
					let indexPathForCell = tableView.indexPath(for: cell)!
					updateCell(cell, atIndexPath: indexPathForCell)
				}
			}
			else {
				tableView.reloadRows(at: [indexPath!], with: rowAnimation)
			}
		case .move:
			tableView.deleteRows(at: [$(indexPath!)], with: rowAnimation)
			tableView.insertRows(at: [$(newIndexPath!)], with: rowAnimation)
		}
	}
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		$(controller)
		if groupingTableUpdatesEnabled {
			($(fetchResultsAnimationEnabled) ? invoke : UIView.performWithoutAnimation) {
				$(self.tableView).endUpdates()
			}
		}
	}
	// MARK: -
	init(tableView: UITableView, updateCell: (UITableViewCell, atIndexPath: IndexPath) -> Void) {
		self.tableView = tableView
		self.updateCell = updateCell
	}
}
