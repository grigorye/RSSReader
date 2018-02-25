//
//  Labeling.swift
//  GETracing
//
//  Created by Grigory Entin on 24.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func descriptionImp<T>(of value: T) -> String {
	if dumpInTraceEnabled {
		var s = ""
		dump(value, to: &s)
		return s
	}
	switch value {
	case let error as Error:
		return description(ofError: error)
	default:
		return description(of: value)
	}
}

let NSDetailedErrorsKey = "NSDetailedErrors"

public func description(ofError error: NSError) -> String {
	let userInfo = error.userInfo

	let (dumpedError, detailedErrors): (NSError, [Error]?) = {
		guard let detailedErrors = userInfo[NSDetailedErrorsKey] as? [Error] else {
			return (error, nil)
		}
		let dumpedUserInfo = userInfo.filter {(key, _) in key != NSDetailedErrorsKey}
		let dumpedError = NSError(domain: error.domain, code: error.code, userInfo: dumpedUserInfo)
		return (dumpedError, detailedErrors)
	}()

	let detailedErrorsDescription: String? = {
		guard let detailedErrors = detailedErrors else {
			return nil
		}
		return "DetailedErrors: \(detailedErrors)"
	}()

	return ["\(dumpedError)", detailedErrorsDescription].flatMap {$0}.joined(separator: " ")
}

public func description(ofError error: Error) -> String {
	let nserror = error as NSError
	return description(ofError: nserror)
}

public func description<T>(of value: T) -> String where T: Any {
	return "\(value)"
}

public func L<T>(file: String = #file, line: Int = #line, column: Int = #column, function: String = #function, dso: UnsafeRawPointer = #dsohandle, _ valueClosure: @autoclosure () -> T) -> String {
	// swiftlint:disable:previous identifier_name
	let value = valueClosure()
	let location = SourceLocation(file: file, line: line, column: column, function: function, moduleReference: .dso(dso))
	let sourceExtractedInfo = GETracing.sourceExtractedInfo(for: location, traceFunctionName: "L")
	let labeled = "\(sourceExtractedInfo.label): \(descriptionImp(of: value))"
	return labeled
}

var dumpInTraceEnabledEnforced: Bool?
private var dumpInTraceEnabled: Bool {
	return dumpInTraceEnabledEnforced ?? UserDefaults.standard.bool(forKey: "dumpInTraceEnabled")
}
