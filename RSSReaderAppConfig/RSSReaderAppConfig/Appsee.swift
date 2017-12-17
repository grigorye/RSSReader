//
//  Appsee.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if ANALYTICS_ENABLED && APPSEE_ENABLED
	import Appsee
	import Foundation
#endif

let appseeInitializer: Void = {
	#if ANALYTICS_ENABLED && APPSEE_ENABLED
		Appsee.start(NSBundle.mainBundle().infoDictionary!["appseeAPIKey"] as! String)
	#endif
}()
