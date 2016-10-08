//
//  Appsee.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !APPSEE_ENABLED

public let appseeInitializer: Void = ()

#else

import Appsee
import Foundation

public let appseeInitializer: Void = {
	Appsee.start(NSBundle.mainBundle().infoDictionary!["appseeAPIKey"] as! String)
}()

#endif
