//
//  DataGenerator.swift
//  RSSReaderDataTests
//
//  Created by Grigory Entin on 14.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

@testable import RSSReaderData
import Foundation

class DataGenerator : NSObject {
	
	public func newFolder(withName name: String) -> Folder {
		
		let folder = Folder(context: mainQueueManagedObjectContext) … {
			
			$0.streamID = name
		}
		return folder
	}
}


