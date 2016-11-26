//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func sourceExtractedInfo(for location: SourceLocation) -> SourceExtractedInfo {
	guard sourceLabelsEnabled else {
		return SourceExtractedInfo(label: descriptionForInLineLocation(location))
	}
	let fileURL = location.fileURL
	let fileName = fileURL.lastPathComponent
	let resourceName = fileURL.deletingPathExtension().lastPathComponent
	let resourceType = fileURL.pathExtension
	var file: String
	switch location.moduleReference {
	case let .dso(dso):
		guard let bundle = Bundle(for: dso) else {
			// Console
			return SourceExtractedInfo(label: "\(resourceName).\(resourceType):?")
		}
		let bundleName = (bundle.bundlePath as NSString).lastPathComponent
		guard let fileInBundle = bundle.path(forResource: resourceName, ofType: resourceType, inDirectory: "Sources") else {
			// File missing in the bundle
			return SourceExtractedInfo(label: "\(bundleName)/\(fileName)[missing]:\(descriptionForInLineLocation(location)):?")
		}
		file = fileInBundle
	case .playground:
		file = fileURL.path
	}
	let fileContents = try! String(contentsOfFile: file, encoding: String.Encoding.utf8)
	let rawLines = fileContents.components(separatedBy: "\n")
	let (lines, playgroundName): ([String], String?) = {
		guard case .playground = location.moduleReference else {
			return (rawLines, nil)
		}
		var i = rawLines.startIndex
		let regularExpression = try! NSRegularExpression(pattern: "#sourceLocation\\(file: \"(.*)\", line: 1\\)")
		for line in rawLines {
			if let match = regularExpression.firstMatch(in: line, range: NSRange(location: 0, length: line.characters.count)) {
				let s = rawLines[(i + 1)..<rawLines.endIndex]
				let playgroundName = (line as NSString).substring(with: match.rangeAt(1)) as String
				return (Array(s), playgroundName)
			}
			i = rawLines.index(after: i)
		}
		fatalError()
	}()
	let line = lines[location.line - 1]
	let distanceToExpr: Int = {
		guard swiftHashColumnMatchesLastComponentInCompoundExpressions else {
			return location.column
		}
		let columnIndex = location.column - 1
		let prefix = line.substring(toOffset: columnIndex)
		let prefixReversed = String(prefix.characters.reversed())
		let indexOfOpeningBracketInPrefixReversed = prefixReversed.range(of: "($")!.lowerBound
		return columnIndex - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let lineTail = line.substring(fromOffset: distanceToExpr)
	let indexOfClosingBracketInTail = lineTail.rangeOfClosingBracket(")", openingBracket: "(")!.lowerBound
	let label = lineTail.substring(to: indexOfClosingBracketInTail)
	return SourceExtractedInfo(label: label, playgroundName: playgroundName)
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

public var swiftHashColumnMatchesLastComponentInCompoundExpressions = true

public var sourceLabelsEnabledEnforced: Bool?

private var sourceLabelsEnabled: Bool {
	return sourceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "sourceLabelsEnabled")
}
