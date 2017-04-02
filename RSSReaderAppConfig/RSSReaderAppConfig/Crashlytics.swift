//
//  CrashlyticsLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !CRASHLYTICS_ENABLED

let crashlyticsInitializer: Void = ()

#else

import struct GETracing.LogRecord
import func GEFoundation.defaultLoggedTextWithThread
import Crashlytics

func crashlyticsLogger(record: LogRecord) {
	let text = defaultLoggedTextWithThread(for: record)
	CLSLogv("%@", getVaList([text]))
}

func crashlyticsErrorTracker(error: Error) {
	Crashlytics.sharedInstance().recordError(error)
}
	
import var GETracing.loggers
import Fabric

let crashlyticsInitializer: Void = {
	Fabric.with([Crashlytics()])
	loggers.append(crashlyticsLogger)
	errorTrackers.append(crashlyticsErrorTracker)
}()

#endif
