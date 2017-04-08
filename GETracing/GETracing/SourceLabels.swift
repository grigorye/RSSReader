//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func sourceExtractedInfo(for location: SourceLocation, traceFunctionName: String) -> SourceExtractedInfo {
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
	let closure = sourceLabelClosuresEnabled
	let adjustedColumn: Int = {
		guard !closure else {
			return location.column
		}
		let columnIndex = line.index(line.startIndex, offsetBy: location.column - (closure ? 0 : 1))
		let prefix = line.substring(to: columnIndex)
		let prefixReversed = String(prefix.characters.reversed())
		let traceFunctionNameReversed = String(traceFunctionName.characters.reversed())
		let rangeOfClosingBracket = prefixReversed.rangeOfClosingBracket("(", openingBracket: ")", followedBy: traceFunctionNameReversed)!
		let indexOfOpeningBracketInPrefixReversed = rangeOfClosingBracket.lowerBound
		return location.column - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let columnIndex = line.index(line.startIndex, offsetBy: adjustedColumn - (closure ? 0 : 1))
	let lineTail = line.substring(from: columnIndex)
	let (openingBracket, closingBracket) = closure ? ("{", "}") : ("(", ")")
	let indexOfClosingBracketInTail = lineTail.rangeOfClosingBracket(closingBracket, openingBracket: openingBracket)!.lowerBound
	let label = lineTail.substring(to: indexOfClosingBracketInTail)
	return SourceExtractedInfo(label: label, playgroundName: playgroundName)
}

private func descriptionForInLineLocation(_ location: SourceLocation) -> String {
	return ".\(location.column + (sourceLabelClosuresEnabled ? 1 : 0))"
}

private extension String {

	func substring(toOffset offset: Int) -> String {
		return substring(to: index(startIndex, offsetBy: offset))
	}
	
	func substring(fromOffset offset: Int) -> String {
		return substring(from: index(startIndex, offsetBy: offset))
	}
	
}

public var sourceLabelsEnabledEnforced: Bool?
public var sourceLabelClosuresEnabled = false

private var sourceLabelsEnabled: Bool {
	return sourceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "sourceLabelsEnabled")
}
