//
//  DefaultLogger.swift
//  GEBase
//
//  Created by Grigory Entin on 14/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

let dateFormatter = DateFormatter() … {
	$0.dateFormat = "HH:mm.ss.SSS"
}

private let traceToNSLogEnabled = false

public func defaultLoggedText(date: Date, label: String, location: SourceLocation, message: String) -> String {
	let locationDescription = "\(location.function), \(location.fileURL.lastPathComponent):\(location.line)"
	let text = "\(locationDescription) ◾︎ \(label): \(message)"
	return text
}

public func defaultLoggedTextWithTimestampAndThread(date: Date, label: String, location: SourceLocation, message: String) -> String {
	let text = defaultLoggedText(date: date, label: label, location: location, message: message)
	let dateDescription = dateFormatter.string(from: date)
	let threadDescription = Thread.isMainThread ? "-" : "\(DispatchQueue.global().label)"
	let textWithTimestampAndThread = "\(dateDescription) [\(threadDescription)] \(text)"
	return textWithTimestampAndThread
}

public func defaultLoggedTextWithThread(date: Date, label: String, location: SourceLocation, message: String) -> String {
	let text = defaultLoggedText(date: date, label: label, location: location, message: message)
	let threadDescription = Thread.isMainThread ? "-" : "\(DispatchQueue.global().label)"
	let textWithThread = "[\(threadDescription)] \(text)"
	return textWithThread
}

func defaultLogger(date: Date, label: String, location: SourceLocation, message: String) {
	if traceToNSLogEnabled {
		let text = defaultLoggedText(date: date, label: label, location: location, message: message)
		NSLog("%@", text)
	}
	else {
		let textWithTimestampAndThread = defaultLoggedTextWithTimestampAndThread(date: date, label: label, location: location, message: message)
		print(textWithTimestampAndThread)
	}
}
