//
//  FetchedObjectBinding.swift
//  GEBase
//
//  Created by Grigory Entin on 22.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

public class FetchedObjectBinding<T> : NSObject, NSFetchedResultsControllerDelegate where T: DefaultSortable, T: Managed, T: NSFetchRequestResult {
	let handler: ([T]) -> Void
	let fetchedResultsController: NSFetchedResultsController<T>
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		handler(controller.fetchedObjects! as! [T])
	}
	public init(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, handler: @escaping ([T]) -> Void) {
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

public class FetchedObjectCountBinding<T> : NSObject, NSFetchedResultsControllerDelegate where T: Managed, T: NSFetchRequestResult {
	let countDidUpdate: Handler
	func managedObjectContextObjectsDidChange() {
		self.countDidUpdate()
	}
	var blocksScheduledForDeinit = [Handler]()
	//
	deinit {
		for i in blocksScheduledForDeinit { i() }
	}
	public init(managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, handler: @escaping (Int) -> Void) {
		do {
			let fetchRequest = T.fetchRequestForEntity() … {
				$0.predicate = _0 ? nil : predicate
			}
			self.countDidUpdate = {
				managedObjectContext.perform {
					handler(try! managedObjectContext.count(for: fetchRequest))
				}
			}
		}
		super.init()
		do {
			let notificationCenter = NotificationCenter.default
			let observer = notificationCenter.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: nil) {
				[weak self] _ in
				self?.managedObjectContextObjectsDidChange()
			}
			self.blocksScheduledForDeinit += [{
				notificationCenter.removeObserver(observer)
			}]
		}
		self.countDidUpdate()
	}
}
