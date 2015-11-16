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

	@NSManaged var traceEnabled: Bool
	@NSManaged var traceLabelsEnabled: Bool
	@NSManaged var showUnreadOnly: Bool
	@NSManaged var authToken: String!
	@NSManaged var login: String!
	@NSManaged var password: String!
	@NSManaged var analyticsEnabled: Bool
	@NSManaged var stateRestorationDisabled: Bool
	@NSManaged var fetchResultsAreAnimated: Bool
	@NSManaged var batchSavingDisabled: Bool
	@NSManaged var itemsAreSortedByLoadDate: Bool
	@NSManaged var foldersLastUpdateDate: NSDate!
	@NSManaged var foldersLastUpdateErrorEncoded: NSData!
	@NSManaged var pageViewsEnabled: Bool

}