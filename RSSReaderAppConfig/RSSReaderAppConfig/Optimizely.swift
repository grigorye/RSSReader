//
//  Optimizely.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 17.01.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

#if !ANALYTICS_ENABLED || !OPTIMIZELY_ENABLED

func launchOptimizely(launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
}

#else

import Optimizely

func launchOptimizely(launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
	Optimizely.start(withAPIToken: "AANaUR4B7B7xxQ8ni7TZkZkivcHQ9MX2~8167430621", launchOptions:launchOptions)
}

#endif
