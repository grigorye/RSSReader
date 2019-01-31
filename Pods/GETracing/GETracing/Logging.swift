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
	public enum Message {
		case multiline(Data)
		case inline(Any)
	}
	public let message: Message
	public let label: String?
	public let date: Date
	public let location: SourceLocation!
}

extension LogRecord.Message {
	func formattedForOutput(prefixedWithLabel: Bool) -> String {
		switch self {
		case .inline(let value):
			return " " + tracedValueDescriptionGenerator(value)
		case .multiline(let data):
			return "\n```\n" + String(data: data, encoding: .utf8)! + "\n```"
		}
	}
}

// Populates log with a given record.
public var logRecord: ((LogRecord) -> Void)? = {
	defaultLog(record: $0)
}

func log(_ value: LoggedValue, on date: Date, at location: SourceLocation, traceFunctionName: StaticString) {
	guard let logRecord = logRecord else {
		return
	}
	let label: String = labelForArguments(of: traceFunctionName, location: location)
	let message = value.logMessage()
	let record = LogRecord(message: message, label: label, date: date, location: location)
	logRecord(record)
}

public func logWithNoSourceOrLabel(_ message: LogRecord.Message) {
	guard let logRecord = logRecord else {
		return
	}
	let record = LogRecord(message: message, label: nil, date: Date(), location: nil)
	logRecord(record)
}
