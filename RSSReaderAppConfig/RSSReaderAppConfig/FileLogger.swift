//
//  FileLogger.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import Foundation

let fileManager = FileManager.default
let logFileNameDateFormatter = DateFormatter() … {
	$0.dateFormat = "yyyy-MM-dd-HHmmss"
}
public let logFileURL: URL = {
	let libraryDirectoryURL = try! fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	let nameWithoutExtension = logFileNameDateFormatter.string(from: Date())
	let name = "\(nameWithoutExtension).log"
	let $ = libraryDirectoryURL.appendingPathComponent("Logs").appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent(name)
	return $
}()
let logFileHandle: FileHandle! = {
	try! fileManager.createDirectory(at: logFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
	guard fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil) else {
		return nil
	}
	return try! FileHandle(forWritingTo: logFileURL)
}()

func fileLogger(date: Date, label: String?, location: SourceLocation, message: String) {
	guard let logFileHandle = logFileHandle else {
		return
	}
	let text = defaultLoggedTextWithTimestampAndThread(date: date, label: label, location: location, message: message) + "\n"
	let data = text.data(using: .utf8)!
	logFileHandle.write(data)
}

let fileLoggerInitializer: Void = {
	$(logFileURL)
	loggers += [fileLogger]
}()
