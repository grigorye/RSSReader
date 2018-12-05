//
//  SourceLabels.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func sourceModuleURLAndSourceFileResourcePath(forSource url: URL) -> (URL, String) {
	
	let ignoredParentDirNames = [
		"Sources",
		"Swift"
	]

	let parentURL = url.deletingLastPathComponent()
	let parentDirName = parentURL.lastPathComponent
	
	if ignoredParentDirNames.contains(parentDirName) {
		return sourceModuleURLAndSourceFileResourcePath(forSource: parentURL)
	}
	
	if parentDirName.hasSuffix("Tests") {
		return (parentURL, [parentDirName, url.lastPathComponent].joined(separator: "/"))
	}
	
	// Yep, make Foo the module name in Foo/Foo/Bar/Baz.swift
	if parentDirName == url.lastPathComponent {
		return (parentURL, parentDirName)
	}
	
	let (sourceModuleURL, parentResourcePath) = sourceModuleURLAndSourceFileResourcePath(forSource: parentURL)
	let resourcePath = [parentResourcePath, url.lastPathComponent].joined(separator: "/")
	return (sourceModuleURL, resourcePath)
}

func sourceExtractedInfo(for location: SourceLocation, traceFunctionName: String) -> SourceExtractedInfo {
	// swiftlint:disable:previous function_body_length
	guard sourceLabelsEnabled else {
		return SourceExtractedInfo(label: descriptionForInLineLocation(location))
	}
	let fileURL = location.fileURL
	let fileName = fileURL.lastPathComponent
	let (sourceModuleURL, resourcePath) = sourceModuleURLAndSourceFileResourcePath(forSource: fileURL)
	let sourceModuleName = sourceModuleURL.lastPathComponent
	let resourceType = fileURL.pathExtension
	let file: String
	switch location.moduleReference {
	case let .dso(dso):
		guard let bundle = Bundle(for: dso) else {
			// Console
			return SourceExtractedInfo(label: "\(resourcePath):?")
		}
		let bundleName = (bundle.bundlePath as NSString).lastPathComponent
		guard let sourcesBundlePath = bundle.path(forResource: "\(sourceModuleName)-Sources", ofType: "bundle") else {
			return SourceExtractedInfo(label: "\(bundleName)/\(fileName)[missing-sources-bundle]:\(descriptionForInLineLocation(location)):?")
		}
		guard let sourcesBundle = Bundle(path: sourcesBundlePath) else {
			return SourceExtractedInfo(label: "\(bundleName)/\(fileName)[non-loadable-sources-bundle]:\(descriptionForInLineLocation(location)):?")
		}
		let resourcePathComponents = resourcePath.components(separatedBy: "/")
		let resourceSubpath = resourcePathComponents.dropLast().joined(separator: "/")
		let resourceName = fileURL.deletingPathExtension().lastPathComponent
		guard let fileInBundle = sourcesBundle.path(forResource: resourceName, ofType: resourceType, inDirectory: resourceSubpath) else {
			return SourceExtractedInfo(label: "\(bundleName)/\(fileName)[missing]:\(descriptionForInLineLocation(location)):?")
		}
		file = fileInBundle
	case .playground:
		file = fileURL.path
	}
	guard let fileContents = try? String(contentsOfFile: file, encoding: String.Encoding.utf8) else {
		assert(false, "Couldn't read \"\(fileURL)\".")
		return SourceExtractedInfo(label: "\(file)[contents-missing]:\(descriptionForInLineLocation(location)):?")
	}
	let rawLines = fileContents.components(separatedBy: "\n")
	let (lines, playgroundName): ([String], String?) = {
		guard case .playground(let playgroundName) = location.moduleReference else {
			return (rawLines, nil)
		}
		return (rawLines, playgroundName)
	}()
	let line = lines[location.line - 1] + lines[location.line...].joined(separator: "\n")
	let adjustedColumn: Int = {
		let columnIndex = line.index(line.startIndex, offsetBy: location.column - 1)
		let prefix = line[..<columnIndex]
		let prefixReversed = String(prefix.reversed())
		let traceFunctionNameReversed = String(traceFunctionName.reversed())
		let rangeOfClosingBracket = prefixReversed.rangeOfClosingBracket("(", openingBracket: ")", followedBy: traceFunctionNameReversed)!
		let indexOfOpeningBracketInPrefixReversed = rangeOfClosingBracket.lowerBound
		return location.column - prefixReversed.distance(from: prefixReversed.startIndex, to: indexOfOpeningBracketInPrefixReversed)
	}()
	let columnIndex = line.index(line.startIndex, offsetBy: adjustedColumn - 1)
	let lineTail = String(line[columnIndex...])
	let (openingBracket, closingBracket) = ("(", ")")
	let indexOfClosingBracketInTail = lineTail.rangeOfClosingBracket(closingBracket, openingBracket: openingBracket)!.lowerBound
	let label = String(lineTail[..<indexOfClosingBracketInTail])
	return SourceExtractedInfo(label: label, playgroundName: playgroundName)
}

private func descriptionForInLineLocation(_ location: SourceLocation) -> String {
	return ".\(location.column)"
}

public var sourceLabelsEnabledEnforced: Bool?

private var sourceLabelsEnabled: Bool {
	return sourceLabelsEnabledEnforced ?? UserDefaults.standard.bool(forKey: "sourceLabelsEnabled")
}
