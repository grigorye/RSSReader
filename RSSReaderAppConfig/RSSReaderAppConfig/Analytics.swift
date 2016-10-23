//
//  Analytics.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import Foundation

public let analyticsEnabled: Bool = {
#if ANALYTICS_ENABLED
	return $(versionIsClean) && $(defaults.analyticsEnabled)
#else
	return false
#endif
}()

extension KVOCompliantUserDefaults {
	@NSManaged var analyticsEnabled: Bool
}
