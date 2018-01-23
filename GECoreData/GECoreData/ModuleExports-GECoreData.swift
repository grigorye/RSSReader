//
//  ModuleExports-GECoreData.swift
//  GECoreData
//
//  Created by Grigory Entin on 09.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GECoreData
import CoreData

typealias DefaultSortable = GECoreData.DefaultSortable
typealias ManagedIdentifiable = GECoreData.ManagedIdentifiable
typealias ManagedObjectContextAutosaver = GECoreData.ManagedObjectContextAutosaver
typealias FetchedObjectBinding = GECoreData.FetchedObjectBinding
typealias FetchedObjectCountBinding = GECoreData.FetchedObjectCountBinding

func typedObjectID<T: NSManagedObject>(for object: T) -> TypedManagedObjectID<T> {
	return GECoreData.typedObjectID(for: object)
}

func typedObjectID<T: NSManagedObject>(for object: T?) -> TypedManagedObjectID<T>? {
	return GECoreData.typedObjectID(for: object)
}

func object<ResultType>(in controller: NSFetchedResultsController<ResultType>, indexedBy delta: Int, from anotherObject: ResultType) -> ResultType? where ResultType : NSManagedObject {

	return GECoreData.object(in: controller, indexedBy: delta, from: anotherObject)
}
