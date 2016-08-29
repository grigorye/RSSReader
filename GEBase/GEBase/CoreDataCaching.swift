//
//  CoreDataCaching.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import CoreData.NSManagedObjectContext
import CoreData.NSManagedObject

private var statefulValueCachesForObjectIDsAssoc: Void?
private var cachingEnabledMOCDidChangeObserverAssoc: Void?
private var cachingEnabledAssoc: Void?
private let notificationCenter = NotificationCenter.default

extension NSManagedObjectContext {
	var statefulValueCachesForObjectIDs: NSMutableDictionary! {
		get {
			return associatedObjectRegeneratedAsNecessary(obj: self, key: &statefulValueCachesForObjectIDsAssoc, type: NSMutableDictionary.self)
		}
		set {
			precondition(nil == newValue)
			objc_setAssociatedObject(self, &statefulValueCachesForObjectIDsAssoc, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
	public var cachingEnabled: Bool {
		get {
			return objc_getAssociatedObject(self, &cachingEnabledAssoc) as! Bool? ?? false
		}
		set {
			objc_setAssociatedObject(self, &cachingEnabledAssoc, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
			if newValue {
				let observer = notificationCenter.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self, queue: nil) { _ in
					self.statefulValueCachesForObjectIDs = nil
				}
				objc_setAssociatedObject(self, &cachingEnabledMOCDidChangeObserverAssoc, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			}
			else {
				let observer = objc_getAssociatedObject(self, &cachingEnabledMOCDidChangeObserverAssoc)!
				notificationCenter.removeObserver(observer)
			}
		}
	}
}

extension NSManagedObject : PropertyCacheable {
	public var actualizedValuesCache: NSMutableDictionary? {
		guard self.managedObjectContext!.cachingEnabled else {
			return nil
		}
		let objectID = self.objectID
		guard !objectID.isTemporaryID else {
			return nil
		}
		precondition(!objectID.isTemporaryID)
		self.managedObjectContext!.processPendingChanges()
		let statefulValueCachesForObjectIDs = self.managedObjectContext!.statefulValueCachesForObjectIDs!
		guard let valuesCache = statefulValueCachesForObjectIDs[objectID] as! NSMutableDictionary? else {
			let newValuesCache = NSMutableDictionary()
			statefulValueCachesForObjectIDs[objectID] = newValuesCache
			return newValuesCache
		}
		return valuesCache
	}
}
