//
//  Analytics.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import class GEFoundation.TypedUserDefaults
import var GEFoundation.versionIsClean
import var GEFoundation.defaults
import GETracing
import Foundation

public let analyticsEnabled: Bool = {
#if ANALYTICS_ENABLED
	return x$(versionIsClean) && x$(defaults.analyticsEnabled)
#else
	return false
#endif
}()

extension TypedUserDefaults {
	@NSManaged var analyticsEnabled: Bool
}
