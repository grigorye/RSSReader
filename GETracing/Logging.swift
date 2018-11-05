//
//  Logging.swift
//  GETracing
//
//  Created by Grigory Entin on 24.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

/// Nothing more than a wrapper around log parameters.

public struct SourceExtractedInfo {
	public let label: String
	public let playgroundName: String?
	init(label: String, playgroundName: String? = nil) {
		self.label = label
		self.playgroundName = playgroundName
	}
}

public struct LogRecord {
	public enum Message {
		case multiline(Data)
		case inline(Any)
	}
	public let message: Message
	public let sourceExtractedInfo: SourceExtractedInfo?
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

extension LogRecord {
	public var label: String? {
		return self.sourceExtractedInfo?.label
	}
	public var playgroundName: String? {
		return self.sourceExtractedInfo?.playgroundName
	}
}

// Populates log with a given record.
public var logRecord: ((LogRecord) -> Void)? = {
	defaultLog(record: $0)
}

func log(_ value: LoggedValue, on date: Date, at location: SourceLocation, traceFunctionName: String) {
	guard let logRecord = logRecord else {
		return
	}
	let sourceExtractedInfo = GETracing.sourceExtractedInfo(for: location, traceFunctionName: traceFunctionName)
	let message = value.logMessage()
	let record = LogRecord(message: message, sourceExtractedInfo: sourceExtractedInfo, date: date, location: location)
	logRecord(record)
}

public func logWithNoSourceOrLabel(_ message: LogRecord.Message) {
	guard let logRecord = logRecord else {
		return
	}
	let record = LogRecord(message: message, sourceExtractedInfo: nil, date: Date(), location: nil)
	logRecord(record)
}
