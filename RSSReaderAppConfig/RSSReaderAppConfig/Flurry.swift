//
//  Flurry.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !FLURRY_ENABLED

public let flurryInitializer: Void = ()

#else

import Foundation

public let flurryInitializer: Void = {
	Flurry.startSession("TSPCHYJBMBGZZFM3SFDZ")
}()

#endif
