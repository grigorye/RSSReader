//
//  Logging.swift
//  GETracing
//
//  Created by Grigory Entin on 24.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

/// Nothing more than a wrapper around log parameters.
public struct LogRecord {
	public let message: String
	public let label: String?
	public let date: Date
	public let location: SourceLocation
}

public typealias Logger = (LogRecord) -> ()

/// Loggers used with `trace`.
public var loggers: [Logger] = [
]

func log<T>(_ value: T, on date: Date, at location: SourceLocation) {
	let label = GETracing.label(for: location)
	let message = descriptionImp(of: value)
	let record = LogRecord(message: message, label: label, date: date, location: location)
	for logger in loggers {
		logger(record)
	}
}
