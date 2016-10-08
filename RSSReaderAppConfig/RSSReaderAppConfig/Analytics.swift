//
//  Analytics.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation
import GEBase

public let analyticsEnabled: Bool = {
#if ANALYTICS_ENABLED
	return $(GEBase.versionIsClean) && $(defaults.analyticsEnabled)
#else
	return false
#endif
}()

extension KVOCompliantUserDefaults {
	@NSManaged var analyticsEnabled: Bool
}
