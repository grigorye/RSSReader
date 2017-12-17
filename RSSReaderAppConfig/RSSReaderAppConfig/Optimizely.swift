//
//  Optimizely.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 17.01.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

#if ANALYTICS_ENABLED && OPTIMIZELY_ENABLED
	import Optimizely
#endif

import UIKit

func launchOptimizely(launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
	
	#if ANALYTICS_ENABLED && OPTIMIZELY_ENABLED
		Optimizely.start(withAPIToken: "AANaUR4B7B7xxQ8ni7TZkZkivcHQ9MX2~8167430621", launchOptions:launchOptions)
	#endif
}
