//
//  ManagedObjectContextAutosaver.swift
//  GEBase
//
//  Created by Grigory Entin on 13.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import CoreData

public class ManagedObjectContextAutosaver: NSObject {
	let notificationCenter = NSNotificationCenter.defaultCenter()
	let observer: AnyObject
	deinit {
		notificationCenter.removeObserver(observer)
	}
	public init(managedObjectContext: NSManagedObjectContext, queue: NSOperationQueue?) {
		observer = notificationCenter.addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: queue, usingBlock: { notification in
			$(notification).$()
			managedObjectContext.performBlock {
				$(managedObjectContext).$()
				if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as! Set<NSManagedObject>? {
					for updatedObject in updatedObjects {
						$($(updatedObject).$().changedValues()).$()
					}
				}
				let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as! Set<NSManagedObject>?
				$(insertedObjects).$()
				let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as! Set<NSManagedObject>?
				$(deletedObjects).$()
				try! managedObjectContext.save()
			}
		})
	}
}