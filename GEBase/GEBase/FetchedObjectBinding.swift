//
//  FetchedObjectBinding.swift
//  GEBase
//
//  Created by Grigory Entin on 22.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

public class FetchedObjectBinding<T where T: DefaultSortable, T: Managed, T: NSFetchRequestResult> : NSObject, NSFetchedResultsControllerDelegate {
	var handler: ([T]) -> Void
	let fetchedResultsController: NSFetchedResultsController<T>
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		handler(controller.fetchedObjects! as! [T])
	}
	public init(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, handler: ([T]) -> Void) {
		self.handler = handler
		self.fetchedResultsController = {
			let fetchRequest = T.fetchRequestForEntity() … {
				$0.predicate = _0 ? nil : predicate
				$0.sortDescriptors = [T.defaultSortDescriptor()]
			}
			let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			return $
		}()
		super.init()
		fetchedResultsController.delegate = self
		try! fetchedResultsController.performFetch()
		handler(fetchedResultsController.fetchedObjects!)
	}
}
