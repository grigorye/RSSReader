//
//  FetchedResultsControllerExtensions.swift
//  GECoreData
//
//  Created by Grigory Entin on 23.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

#if os(iOS)
import UIKit
import CoreData

public func object<ResultType>(in controller: NSFetchedResultsController<ResultType>, indexedBy delta: Int, from anotherObject: ResultType) -> ResultType? where ResultType : NSManagedObject {
	
	guard let anotherIndexPath = controller.indexPath(forObject: anotherObject) else {
		return nil
	}
	let section = anotherIndexPath.section
	let row = anotherIndexPath.row + delta
	guard 0 <= row else {
		return nil
	}
	guard row < controller.sections![section].numberOfObjects else {
		return nil
	}
	return controller.object(at: IndexPath(indexes: [section, row]))
}
#endif
