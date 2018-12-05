//
//  Answers.swift
//  GEAppConfig
//
//  Created by Grigory Entin on 27.10.18.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

#if GEAPPCONFIG_ANALYTICS_ENABLED && GEAPPCONFIG_ANSWERS_ENABLED
import Fabric
import Crashlytics
#endif

let answersInitializer: Void = {
    #if GEAPPCONFIG_ANALYTICS_ENABLED && GEAPPCONFIG_ANSWERS_ENABLED
    Fabric.with([Answers()])
    #endif
}()
