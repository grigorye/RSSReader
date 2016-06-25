//
//  FetchedObjectBinding.swift
//  GEBase
//
//  Created by Grigory Entin on 22.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

public class FetchedObjectBinding<T where T: DefaultSortable, T: Managed, T: NSFetchRequestResult> : NSObject, NSFetchedResultsControllerDelegate {
	var handler: (T?) -> Void
	let fetchedResultsController: NSFetchedResultsController<T>
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		let object = controller.fetchedObjects!.last as! T?
		handler(object)
	}
	public init(managedObjectContext: NSManagedObjectContext, predicate: Predicate?, handler: (T?) -> Void) {
		self.handler = { object in
			handler(object)
		}
		self.fetchedResultsController = {
			let fetchRequest: NSFetchRequest<T> = {
				let $ = T.fetchRequestForEntity()
				$.predicate = _0 ? nil : predicate
				$.sortDescriptors = [T.defaultSortDescriptor()]
				return $
			}()
			let $ = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			return $
		}()
		super.init()
		fetchedResultsController.delegate = self
		try! fetchedResultsController.performFetch()
		handler(fetchedResultsController.fetchedObjects!.last)
	}
}
