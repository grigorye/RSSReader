//
//  CrashlyticsLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 07.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation
import Crashlytics

func crashlyticsLogger(date: Date, label: String, location: SourceLocation, message: String) {
	let text = defaultLoggedTextWithThread(date: date, label: label, location: location, message: message)
	CLSLogv("%@", getVaList([text]))
}
