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
	let notificationCenter = NotificationCenter.default
	let observer: AnyObject
	deinit {
		notificationCenter.removeObserver(observer)
	}
	public init(managedObjectContext: NSManagedObjectContext, queue: OperationQueue?) {
		observer = notificationCenter.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: queue, using: { notification in
			•(notification)
			managedObjectContext.perform {
				•(managedObjectContext)
				if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as! Set<NSManagedObject>? {
					for updatedObject in updatedObjects {
						•((updatedObject).changedValues())
					}
					x$(updatedObjects.count)
				}
				if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as! Set<NSManagedObject>? {
					•(insertedObjects)
					x$(insertedObjects.count)
				}
				if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as! Set<NSManagedObject>? {
					•(deletedObjects)
					x$(deletedObjects.count)
				}
				try! managedObjectContext.save()
			}
		})
	}
}
