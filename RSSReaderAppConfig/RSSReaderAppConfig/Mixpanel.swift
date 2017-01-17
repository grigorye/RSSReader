//
//  Mixpanel.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 17.01.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !MIXPANEL_ENABLED

let mixpanelInitializer: Void = ()

#else

import Mixpanel
import Foundation

let mixpanelInitializer: Void = {
	Mixpanel.initialize(token: "2771a9a726146c01941e2416a6442b48")
}()

#endif
