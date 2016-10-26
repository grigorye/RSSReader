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

import GEFoundation
import GETracing
import Fabric
import Crashlytics
import Foundation

func crashlyticsLogger(record: LogRecord) {
	let text = defaultLoggedTextWithThread(for: record)
	CLSLogv("%@", getVaList([text]))
}

let crashlyticsInitializer: Void = {
	Fabric.with([Crashlytics()])
	loggers.append(crashlyticsLogger)
}()

#endif
