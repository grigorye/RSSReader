//
//  FileLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import func GETracing.x$
import func GETracing.loggedText
import typealias GETracing.LogRecord
import Foundation

let fileManager = FileManager.default
let logFileNameDateFormatter = DateFormatter() … {
	$0.dateFormat = "yyyy-MM-dd-HHmmss"
}

public let logFileURL: URL = {
	let libraryDirectoryURL = try! fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	let nameWithoutExtension = logFileNameDateFormatter.string(from: Date())
	let name = "\(nameWithoutExtension).log"
	let x = libraryDirectoryURL.appendingPathComponent("Logs").appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(name)
	return x
}()

public let logFileHandle: FileHandle! = {
	try! fileManager.createDirectory(at: logFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
	guard fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil) else {
		return nil
	}
	return try! FileHandle(forWritingTo: logFileURL)
}()

func fileLogger(record: LogRecord) {
	guard let logFileHandle = logFileHandle else {
		return
	}
	let text = loggedText(for: record, timestampEnabled: true) {
		"\($0.locationPrefix)\($0.timestampPrefix)[\($0.threadDescription)] \($0.message)\n"
	}
	let data = text.data(using: .utf8)!
	logFileHandle.write(data)
}

import var GETracing.logRecord

let fileLoggerInitializer: Void = {
	x$(logFileURL)
	let oldLogRecord = logRecord
	logRecord = {
		oldLogRecord?($0)
		fileLogger(record: $0)
	}
}()
