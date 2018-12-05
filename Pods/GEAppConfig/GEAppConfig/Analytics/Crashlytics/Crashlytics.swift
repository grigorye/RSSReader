//
//  CrashlyticsLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if GEAPPCONFIG_ANALYTICS_ENABLED && GEAPPCONFIG_CRASHLYTICS_ENABLED

import GEFoundation
import struct GETracing.LogRecord
import var GETracing.logRecord
import func GETracing.loggedText
import Crashlytics
import Fabric

func crashlyticsLogRecord(_ record: LogRecord) {
    let text = loggedText(for: record)
    CLSLogv("%@", getVaList([text]))
}

func crashlyticsErrorTracker(error: Error) {
    Crashlytics.sharedInstance().recordError(error)
}

#endif

let crashlyticsInitializer: Void = {
    #if GEAPPCONFIG_ANALYTICS_ENABLED && GEAPPCONFIG_CRASHLYTICS_ENABLED
    Fabric.with([Crashlytics()])
    let oldLogRecord = logRecord
    logRecord = {
        oldLogRecord?($0)
        crashlyticsLogRecord($0)
    }
    errorTrackers.append(crashlyticsErrorTracker)
    #endif
}()
