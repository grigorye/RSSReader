//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

extension String {
	
	func substring(with range: NSRange) -> String {
		return (self as NSString).substring(with: range) as String
	}
	
}

func sourceModuleNameFor(_ url: URL) -> String {
	
	let ignoredParentDirNames = [
		"Sources",
		"Swift"
	]

	let parentURL = url.deletingLastPathComponent()
	let parentDirName = parentURL.lastPathComponent
	
	guard !ignoredParentDirNames.contains(parentDirName) else {
		return sourceModuleNameFor(parentURL)
	}
	
	return parentDirName
}

func sourceExtractedInfo(for location: SourceLocation, traceFunctionName: String) -> SourceExtractedInfo {
	// swiftlint:disable:previous function_body_length
	guard sourceLabelsEnabled else {
		return SourceExtractedInfo(label: descriptionForInLineLocation(location))
	}
	let fileURL = location.fileURL
	let fileName = fileURL.lastPathComponent
	let resourceName = fileURL.deletingPathExtension().lastPathComponent
	let resourceType = fileURL.pathExtension
	let sourceModuleName = sourceModuleNameFor(fileURL)
	let file: String
	switch location.moduleReference {
	case let .dso(dso):
		guard let bundle = Bundle(for: dso) else {
			// Console
			return SourceExtractedInfo(label: "\(resourceName).\(resourceType):?")
		}
		let bundleName = (bundle.bundlePath as NSString).lastPathComponent
		let directory = ["Sources", sourceModuleName].joined(separator: "/")
		guard let fileInBundle = bundle.path(forResource: resourceName, ofType: resourceType, inDirectory: directory) else {
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
			if let match = regularExpression.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) {
				let s = rawLines[(i + 1)..<rawLines.endIndex]
				let playgroundName = line.substring(with: match.range(at: 1))
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
		let prefix = line[..<columnIndex]
		let prefixReversed = String(prefix.reversed())
		let traceFunctionNameReversed = String(traceFunctionName.reversed())
		let rangeOfClosingBracket = prefixReversed.rangeOfClosingBracket("(", openingBracket: ")", followedBy: traceFunctionNameReversed)!
		let indexOfOpeningBracketInPrefixReversed = rangeOfClosingBracket.lowerBound
		return location.column - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let columnIndex = line.index(line.startIndex, offsetBy: adjustedColumn - (closure ? 0 : 1))
	let lineTail = String(line[columnIndex...])
	let (openingBracket, closingBracket) = closure ? ("{", "}") : ("(", ")")
	let indexOfClosingBracketInTail = lineTail.rangeOfClosingBracket(closingBracket, openingBracket: openingBracket)!.lowerBound
	let label = String(lineTail[..<indexOfClosingBracketInTail])
	return SourceExtractedInfo(label: label, playgroundName: playgroundName)
}

private func descriptionForInLineLocation(_ location: SourceLocation) -> String {
	return ".\(location.column + (sourceLabelClosuresEnabled ? 1 : 0))"
}

public var sourceLabelsEnabledEnforced: Bool?
public var sourceLabelClosuresEnabled = false

private var sourceLabelsEnabled: Bool {
	return sourceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "sourceLabelsEnabled")
}
