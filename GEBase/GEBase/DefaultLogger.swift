//
//  DefaultLogger.swift
//  GEBase
//
//  Created by Grigory Entin on 14/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

let dateFormatter: NSDateFormatter = {
	let $ = NSDateFormatter()
	$.dateFormat = "HH:mm.ss.SSS"
	return $
}()

private let traceToNSLogEnabled = false

func defaultLogger(date: NSDate, label: String, location: SourceLocation, message: String) {
	let locationDescription = "\(location.fileURL.lastPathComponent!):\(location.line): \(location.function)"
	let text = "\(locationDescription) ◾︎ \(label): \(message)"
	if traceToNSLogEnabled {
		NSLog("%@", text)
	}
	else {
		let dateDescription = dateFormatter.stringFromDate(date)
		let threadDescription = NSThread.isMainThread() ? "-" : "\(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))"
		let textWithTimestamp = "\(dateDescription) [\(threadDescription)] \(text)"
		print(textWithTimestamp)
	}
}
