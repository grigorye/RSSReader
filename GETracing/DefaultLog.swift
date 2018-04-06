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

public func defaultLogText(_ text: String) {
	print(text)
}

/// Returns text for logging given record.
public var loggedTextForRecord = { (record: LogRecord) in
	return defaultLoggedText(for: record)
}

public func defaultLoggedText(for record: LogRecord) -> String {
	let message = loggedMessageForRecord(record)
	let threadDescription = loggedThreadDescription()
	let text = "\(locationPrefix)[\(threadDescription)] \(message)"
	return text
}

// MARK: -

/// Returns message (vs location prefix/thread description) part for logging given record.
public var loggedMessageForRecord = { (record: LogRecord) in
	return defaultLoggedMessage(for: record)
}

public func defaultLoggedMessage(for record: LogRecord) -> String {
	guard let location = record.location else {
		return "\(messagePrefix)\(record.message)"
	}
	let locationDescription = "\(record.playgroundName ?? location.fileURL.lastPathComponent):\(location.line)|\(location.function)"
	guard let label = record.label else {
		return "\(locationDescription)\(sep)\(messagePrefix)\(record.message)"
	}
	return "\(locationDescription)\(sep)\(messagePrefix)\(label): \(record.message)"
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

