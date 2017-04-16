//
//  Analytics.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import var GEFoundation.versionIsClean
import Foundation

public let analyticsEnabled: Bool = {
#if ANALYTICS_ENABLED
	return $(versionIsClean) && $(defaults.analyticsEnabled)
#else
	return false
#endif
}()

extension TypedUserDefaults {
	@NSManaged var analyticsEnabled: Bool
}

private func defaultErrorTracker(error: Error) {
	_ = $(error)
}

var errorTrackers: [(Error) -> ()] = [defaultErrorTracker]

public func trackError(_ error: Error) {
	for errorTracker in errorTrackers {
		errorTracker(error)
	}
}
