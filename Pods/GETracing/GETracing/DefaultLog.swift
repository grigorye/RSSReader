//
//  DefaultLog.swift
//  GEBase
//
//  Created by Grigory Entin on 14/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

// MARK: - Main Logging

public func defaultLog(record: LogRecord) {
	let text = loggedTextForRecord(record)
	logText(text)
}

// MARK: - Output and Text Generation

/// Outputs log text.
public var logText = { (text: String) in
	defaultLogText(text)
}

public var defaultLoggedTextTerminator: String {
	return separatePrefixAndMessageWithNewLine ? "\n\n" : "\n"
}

public func defaultLogText(_ text: String) {
	print(text, terminator: defaultLoggedTextTerminator)
}

/// Returns text for logging given record.
public var loggedTextForRecord = { (record: LogRecord) in
	return loggedText(for: record)
}

let dateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	dateFormatter.dateFormat = "HH:mm.ss.SSS"
	return dateFormatter
}()

public struct LoggedTextFormatArgs {
	public let locationPrefix: String
	public let timestampPrefix: String
	public let threadDescription: String
	public let message: String
}

public typealias LoggedTextFormat = (LoggedTextFormatArgs) -> String

public var defaultLoggedTextFormat: LoggedTextFormat = {
	"\($0.locationPrefix)\($0.timestampPrefix)[\($0.threadDescription)] \($0.message)"
}

public func loggedTextFormatArgs(for record: LogRecord, timestampEnabled: Bool = false) -> LoggedTextFormatArgs {
	let message = loggedMessageForRecord(record)
	let threadDescription = loggedThreadDescription()
	let timestampPrefix: String = {
		guard timestampEnabled else {
			return ""
		}
		return dateFormatter.string(from: record.date) + " "
	}()
	let formatArgs = LoggedTextFormatArgs(
		locationPrefix: locationPrefix,
		timestampPrefix: timestampPrefix,
		threadDescription: threadDescription,
		message: message
	)
	return formatArgs
}

public func loggedText(for record: LogRecord, timestampEnabled: Bool = false, format: LoggedTextFormat = defaultLoggedTextFormat) -> String {
	let formatArgs = loggedTextFormatArgs(for: record, timestampEnabled: timestampEnabled)
	let text = format(formatArgs)
	return text
}

// MARK: -

/// Returns message (vs location prefix/thread description) part for logging given record.
public var loggedMessageForRecord = { (record: LogRecord) in
	return defaultLoggedMessage(for: record)
}

public func locationDescription(for record: LogRecord) -> String? {
	guard let location = record.location else {
		return nil
	}
	// Substitute something more human-readable for #function of top level code of the playground, that is otherwise something like "__lldb_expr_xxx"
	let function: StaticString = {
		guard location.function.description.hasPrefix("__lldb_expr_") else {
			return location.function
		}
		return "<top-level>"
	}()
	
	let locationDescription = "\(location.sourceName):\(location.line)|\(function)"
	return locationDescription
}

public func defaultLoggedMessage(for record: LogRecord) -> String {
	guard let locationDescription = locationDescription(for: record) else {
		return messagePrefix + record.message.formattedForOutput(prefixedWithLabel: false)
	}
	guard let label = record.label else {
		return "\(locationDescription)\(sep)\(messagePrefix)" + record.message.formattedForOutput(prefixedWithLabel: false)
	}
	return "\(locationDescription)\(sep)\(messagePrefix)\(label):" + record.message.formattedForOutput(prefixedWithLabel: true)
}

/// Returns thread description (vs location prefix/message) part for logging given record.
public var loggedThreadDescription = {
	return defaultLoggedThreadDescription()
}

func defaultLoggedThreadDescription() -> String {
	return Thread.isMainThread ? "-" : "\(DispatchQueue.currentQueueLabel!)"
}

/// Returns location
public var locationPrefix: String {
	return locationPrefixGenerator()
}

public var separatePrefixAndMessageWithNewLine = true

public var locationPrefixGenerator = {
	return separatePrefixAndMessageWithNewLine ? "◾︎ " : ""
}

public var messagePrefixGenerator = {
	return separatePrefixAndMessageWithNewLine ? "" : "◾︎ "
}
private var messagePrefix: String {
	return messagePrefixGenerator()
}

private let sep = separatePrefixAndMessageWithNewLine ? "\n" : " "
