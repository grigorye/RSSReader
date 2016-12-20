//
//  CategoryItem.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 20.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import CoreData

public class CategoryItem : NSManagedObject {

	@NSManaged public var category: Folder
	@NSManaged public var item: Item
	
	public class func entityName() -> String {
		return "CategoryItem"
	}
}
