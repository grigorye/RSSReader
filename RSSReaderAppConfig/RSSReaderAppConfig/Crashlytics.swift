//
//  CrashlyticsLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if ANALYTICS_ENABLED && CRASHLYTICS_ENABLED
	
	import GEFoundation
	import struct GETracing.LogRecord
	import var GETracing.loggers
	import Crashlytics
	import Fabric
	
	func crashlyticsLogger(record: LogRecord) {
		let text = defaultLoggedTextWithThread(for: record)
		CLSLogv("%@", getVaList([text]))
	}
	
	func crashlyticsErrorTracker(error: Error) {
		Crashlytics.sharedInstance().recordError(error)
	}
	
#endif

let crashlyticsInitializer: Void = {
	#if ANALYTICS_ENABLED && CRASHLYTICS_ENABLED
		Fabric.with([Crashlytics()])
		loggers.append(crashlyticsLogger)
		errorTrackers.append(crashlyticsErrorTracker)
	#endif
}()
