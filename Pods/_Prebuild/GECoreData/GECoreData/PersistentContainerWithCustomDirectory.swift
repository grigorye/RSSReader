//
//  PersistentContainerWithCustomDirectory.swift
//  GECoreData
//
//  Created by Grigory Entin on 15.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import CoreData

public class PersistentContainerWithCustomDirectory : NSPersistentContainer {
	
	public static var customDirectoryURL: URL?
	
	override public class func defaultDirectoryURL() -> URL {
		
		guard let customDirectoryURL = customDirectoryURL else {
			return super.defaultDirectoryURL()
		}
		
		return customDirectoryURL
	}
}
