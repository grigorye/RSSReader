//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func descriptionForInLineLocation(_ firstLocation: SourceLocation, lastLocation: SourceLocation) -> String {
	return "[\(firstLocation.column)-\(lastLocation.column - 3)]"
}

func label(from firstLocation: SourceLocation, to lastLocation: SourceLocation) -> String {
	let fileURL = firstLocation.fileURL
	let resourceName = fileURL.deletingPathExtension().lastPathComponent
	let resourceType = fileURL.pathExtension
	guard let bundle = firstLocation.bundle else {
		// Console
		return "\(resourceName).\(resourceType):?"
	}
	let bundleName = (bundle.bundlePath as NSString).lastPathComponent
	guard let file = bundle.path(forResource: resourceName, ofType: resourceType, inDirectory: "Sources") else {
		// File missing in the bundle
		return "\(bundleName)/\(resourceName).\(resourceType)[!exist]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	guard let fileContents = try? String(contentsOfFile: file, encoding: String.Encoding.utf8) else {
		return "\(bundleName)/\(resourceName).\(resourceType)[!read]:\(descriptionForInLineLocation(firstLocation, lastLocation: lastLocation)):?"
	}
	let lines = fileContents.components(separatedBy: "\n")
	let line = lines[firstLocation.line - 1]
	let firstIndex: Int = {
		let prefix = line.substring(toOffset: firstLocation.column - 1)
		let prefixReversed = String(prefix.characters.reversed())
		let indexOfOpeningBracketInPrefixReversed = prefixReversed.range(of: "(")!.lowerBound
		return firstLocation.column - 1 - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let lineSuffix = line.substring(fromOffset: firstIndex)
	let lengthInLineSuffix: Int = {
		guard firstLocation.column != lastLocation.column else {
			let indexOfClosingBracket = lineSuffix.rangeOfClosingBracket(")", openingBracket: "(")!.lowerBound
			return lineSuffix.distance(from: lineSuffix.startIndex, to: indexOfClosingBracket)
		}
		return lastLocation.column - firstLocation.column - 3
	}()
	let suffix = lineSuffix.substring(toOffset: lengthInLineSuffix)
	guard swiftHashColumnMatchesLastComponentInCompoundExpressions else {
		return suffix
	}
	let linePrefixReversed = String(line.substring(toOffset: firstIndex).characters.reversed())
	let lengthInLinePrefixReversed: Int = {
		guard firstLocation.column != lastLocation.column else {
			let indexOfClosingBracket = linePrefixReversed.rangeOfClosingBracket("(", openingBracket: ")")!.lowerBound
			return linePrefixReversed.distance(from: linePrefixReversed.startIndex, to: indexOfClosingBracket)
		}
		return 0
	}()
	let prefix = String(linePrefixReversed.substring(toOffset: lengthInLinePrefixReversed).characters.reversed())
	let text = prefix + suffix
	return text
}
