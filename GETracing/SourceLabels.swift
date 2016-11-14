//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func label(for location: SourceLocation) -> String {
	guard sourceLabelsEnabled else {
		return descriptionForInLineLocation(location)
	}
	let fileURL = location.fileURL
	let fileName = fileURL.lastPathComponent
	let resourceName = fileURL.deletingPathExtension().lastPathComponent
	let resourceType = fileURL.pathExtension
	guard let bundle = Bundle(for: location.dso) else {
		// Console
		return "\(resourceName).\(resourceType):?"
	}
	let bundleName = (bundle.bundlePath as NSString).lastPathComponent
	guard let file = bundle.path(forResource: resourceName, ofType: resourceType, inDirectory: "Sources") else {
		// File missing in the bundle
		return "\(bundleName)/\(fileName)[missing]:\(descriptionForInLineLocation(location)):?"
	}
	let fileContents = try! String(contentsOfFile: file, encoding: String.Encoding.utf8)
	let lines = fileContents.components(separatedBy: "\n")
	let line = lines[location.line - 1]
	let firstIndex: Int = {
		let prefix = line.substring(toOffset: location.column - 1)
		let prefixReversed = String(prefix.characters.reversed())
		let indexOfOpeningBracketInPrefixReversed = prefixReversed.range(of: "(")!.lowerBound
		return location.column - 1 - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let lineSuffix = line.substring(fromOffset: firstIndex)
	let lengthInLineSuffix: Int = {
		let indexOfClosingBracket = lineSuffix.rangeOfClosingBracket(")", openingBracket: "(")!.lowerBound
		return lineSuffix.distance(from: lineSuffix.startIndex, to: indexOfClosingBracket)
	}()
	let suffix = lineSuffix.substring(toOffset: lengthInLineSuffix)
	guard swiftHashColumnMatchesLastComponentInCompoundExpressions else {
		return suffix
	}
	let linePrefixReversed = String(line.substring(toOffset: firstIndex).characters.reversed())
	let lengthInLinePrefixReversed: Int = {
		let indexOfClosingBracket = linePrefixReversed.rangeOfClosingBracket("(", openingBracket: ")")!.lowerBound
		return linePrefixReversed.distance(from: linePrefixReversed.startIndex, to: indexOfClosingBracket)
	}()
	let prefix = String(linePrefixReversed.substring(toOffset: lengthInLinePrefixReversed).characters.reversed())
	let text = prefix + suffix
	return text
}

private func descriptionForInLineLocation(_ location: SourceLocation) -> String {
	return ".\(location.column)"
}

private extension String {

	func substring(toOffset offset: Int) -> String {
		return substring(to: index(startIndex, offsetBy: offset))
	}
	
	func substring(fromOffset offset: Int) -> String {
		return substring(from: index(startIndex, offsetBy: offset))
	}
	
}

var swiftHashColumnMatchesLastComponentInCompoundExpressions = true

var sourceLabelsEnabledEnforced: Bool?

private var sourceLabelsEnabled: Bool {
	return sourceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "sourceLabelsEnabled")
}
