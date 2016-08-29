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

func defaultLogger(date: Date, label: String, location: SourceLocation, message: String) {
	let locationDescription = "\(location.function), \(location.fileURL.lastPathComponent):\(location.line)"
	let text = "\(locationDescription) ◾︎ \(label): \(message)"
	if traceToNSLogEnabled {
		NSLog("%@", text)
	}
	else {
		let dateDescription = dateFormatter.string(from: date)
		let threadDescription = Thread.isMainThread ? "-" : "\(DispatchQueue.global().label)"
		let textWithTimestamp = "\(dateDescription) [\(threadDescription)] \(text)"
		print(textWithTimestamp)
	}
}
