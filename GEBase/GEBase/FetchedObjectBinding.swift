//
//  FetchedObjectBinding.swift
//  GEBase
//
//  Created by Grigory Entin on 22.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

public class FetchedAnyObjectBinding : NSObject, NSFetchedResultsControllerDelegate {
	var handler: ((AnyObject?) -> Void)!
	let fetchedResultsController: NSFetchedResultsController
	public func controllerDidChangeContent(controller: NSFetchedResultsController) {
		let object: AnyObject? = controller.fetchedObjects!.last
		handler(object)
	}
	public init(entityName: String, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptor: NSSortDescriptor, handler: (AnyObject?) -> Void) {
		self.handler = handler
		self.fetchedResultsController = {
			let fetchRequest: NSFetchRequest = {
				let $ = NSFetchRequest(entityName: entityName)
				$.predicate = _0 ? nil : predicate
				$.sortDescriptors = [sortDescriptor]
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
public class FetchedObjectBinding<T where T: DefaultSortable, T: Managed> : FetchedAnyObjectBinding  {
	public init(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, handler: (T?) -> Void) {
		super.init(entityName: T.entityName(), managedObjectContext: managedObjectContext, predicate: predicate, sortDescriptor: T.defaultSortDescriptor(), handler: { object in
			handler(object as! T?)
		})
	}
	deinit {
	}
}
