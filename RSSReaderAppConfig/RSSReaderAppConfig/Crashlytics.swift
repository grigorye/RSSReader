//
//  CrashlyticsLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !CRASHLYTICS_ENABLED

public let crashlyticsInitializer: Void = ()

#else

import GEBase
import Fabric
import Crashlytics
import Foundation

func crashlyticsLogger(date: Date, label: String, location: SourceLocation, message: String) {
	let text = defaultLoggedTextWithThread(date: date, label: label, location: location, message: message)
	CLSLogv("%@", getVaList([text]))
}

public let crashlyticsInitializer: Void = {
	Fabric.with([Crashlytics()])
	loggers.append(crashlyticsLogger)
}()

#endif
