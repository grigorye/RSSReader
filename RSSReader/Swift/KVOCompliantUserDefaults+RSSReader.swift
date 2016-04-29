//
//  KVOCompliantUserDefaults+RSSReader.swift
//  RSSReader
//
//  Created by Grigory Entin on 16/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation
import GEBase

extension KVOCompliantUserDefaults {

	@NSManaged var foldersLastUpdateDate: NSDate!
	@NSManaged var foldersLastUpdateErrorEncoded: NSData!
	//
	@NSManaged var login: String!
	@NSManaged var password: String!
	@NSManaged var showUnreadOnly: Bool
	//
	@NSManaged var traceEnabled: Bool
	@NSManaged var traceLabelsEnabled: Bool
	@NSManaged var analyticsEnabled: Bool
	@NSManaged var stateRestorationEnabled: Bool
	@NSManaged var fetchResultsAnimationEnabled: Bool
	@NSManaged var groupingTableUpdatesEnabled: Bool
	@NSManaged var updateCellsInPlaceEnabled: Bool
	@NSManaged var memoryProfilingEnabled: Bool
	@NSManaged var pageViewsEnabled: Bool
	@NSManaged var hideBarsOnSwipe: Bool
	//
	@NSManaged var numberOfItemsToLoadPastVisible: Int
	@NSManaged var numberOfItemsToLoadInitially: Int
	@NSManaged var numberOfItemsToLoadLater: Int
	@NSManaged var fetchBatchSize: Int

}
