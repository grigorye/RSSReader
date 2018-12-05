//
//  DefaultLogger.swift
//  GEBase
//
//  Created by Grigory Entin on 14/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import struct GETracing.LogRecord
import func GETracing.loggedText
import Foundation
import os

private var bundleLogAssoc: Void?

@available(iOS 10.0, macOS 10.12, *)
extension Bundle {
	public var log: OSLog {
		return associatedObjectRegeneratedAsNecessary(obj: self, key: &bundleLogAssoc) {
            return OSLog(subsystem: self.bundleIdentifier!, category: "default")
		}
	}
}

let dateFormatter = DateFormatter() … {
	$0.dateFormat = "HH:mm.ss.SSS"
}

enum DefaultLogKind: String {
	case none, oslog, nslog, print
}

extension TypedUserDefaults {
	@NSManaged var defaultLogKind: String?
	@NSManaged var defaultLogPrintTimestamps: Bool
}

// void rdar_os_log_object_with_type(void const *dso, os_log_t log, os_log_type_t type, id object);

@available(iOS 10.0, macOS 10.12, watchOS 3.0, tvOS 10.0, *)
@_silgen_name("rdar_os_log_object_with_type") private func rdar_os_log_object_with_type(_ dso: UnsafeRawPointer?, _ log: OSLog, _ type: OSLogType, _ object: AnyObject)

public func defaultLogger(record: LogRecord) {
	guard let defaultLogKind = defaults.defaultLogKind else { return }
	switch DefaultLogKind(rawValue: defaultLogKind)! {
	case .none: ()
	case .oslog:
		let text = loggedText(for: record)
		if #available(iOS 10.0, macOS 10.12, *), let location = record.location, case .dso(let dso) = location.moduleReference {
			let bundle = Bundle(for: dso)!
			rdar_os_log_object_with_type(dso, bundle.log, .default, text as NSString)
		} else {
			fallthrough
		}
	case .nslog:
		let text = loggedText(for: record)
		NSLog("%@", text)
	case .print:
		let text = loggedText(for: record, timestampEnabled: defaults.defaultLogPrintTimestamps)
		print(text)
	}
}
