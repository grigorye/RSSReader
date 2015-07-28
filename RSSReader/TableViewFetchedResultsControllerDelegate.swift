//
//  TableViewFetchedResultsControllerDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import CoreData.NSFetchedResultsController
import UIKit.UITableView

private var fetchResultsAreAnimated: Bool {
	return defaults.fetchResultsAreAnimated
}

protocol TableViewFetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate {
	var tableView: UITableView! { get }
	var fetchedResultsController: NSFetchedResultsController { get }
	func configureCell(cell: UITableViewCell, atIndexPath: NSIndexPath)
}

extension TableViewFetchedResultsControllerDelegate {
	var rowAnimation: UITableViewRowAnimation { return UITableViewRowAnimation.None }
	// MARK: -
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		precondition(controller == fetchedResultsController)
		$(controller).$()
		let managedObjectContext = controller.managedObjectContext
		assert(managedObjectContext == mainQueueManagedObjectContext)
		for updatedObject in managedObjectContext.updatedObjects {
			$($(updatedObject).$().changedValues()).$()
		}
		$(managedObjectContext.insertedObjects).$()
		($(fetchResultsAreAnimated).$() ? invoke : UIView.performWithoutAnimation) {
			self.tableView.beginUpdates()
		}
	}
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		precondition(controller == fetchedResultsController)
		$(controller).$()
		$(stringFromFetchedResultsChangeType(type)).$()
		switch type {
		case .Insert:
			tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
		case .Delete:
			tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
		default:
			abort()
		}
	}
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		precondition(controller == fetchedResultsController)
		let tableView = self.tableView!
		$(controller).$()
		$(stringFromFetchedResultsChangeType(type)).$()
		switch type {
		case .Insert:
			$(tableView.numberOfRowsInSection($(newIndexPath!).$().section)).$()
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
		case .Delete:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
		case .Update:
			$(tableView.numberOfRowsInSection($(indexPath!).$().section)).$()
			if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
				self.configureCell(cell, atIndexPath: indexPath!)
			}
		case .Move:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: rowAnimation)
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: rowAnimation)
		}
	}
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		$(controller).$()
		precondition(controller == fetchedResultsController)
		($(fetchResultsAreAnimated).$() ? invoke : UIView.performWithoutAnimation) {
			self.tableView.endUpdates()
		}
	}
}