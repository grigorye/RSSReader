//
//  SourceFiles.swift
//  GETracing
//
//  Created by Grigory Entin on 28/01/2019.
//

import Foundation

func sourceModuleURLAndSourceFileResourcePath(forSource url: URL) -> (URL, String) {
	
	let parentURL = url.deletingLastPathComponent()
	let parentDirName = parentURL.lastPathComponent
	
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

public func sourceFileURLFor(file: StaticString, dso: UnsafeRawPointer) throws -> URL {
	enum Error : Swift.Error {
		case missingBundleForDSO(file: StaticString)
		case missingSourcesBundle(file: StaticString, dsoBundleURL: URL, sourcesBundleName: String)
		case nonLoadableSourcesBundle(file: StaticString, sourcesBundleURL: URL)
		case missingFileInSourcesBundle(file: StaticString, sourcesBundleURL: URL, subdirectory: String)
	}
	guard let dsoBundle = Bundle(for: dso) else {
		// Console?
		throw Error.missingBundleForDSO(file: file)
	}
	
	let fileURL = URL(fileURLWithPath: file.description)
	let (sourceModuleURL, resourcePath) = sourceModuleURLAndSourceFileResourcePath(forSource: fileURL)
	let sourceModuleName = sourceModuleURL.lastPathComponent
	let sourcesBundleName = "\(sourceModuleName)-Sources"
	guard let sourcesBundleURL = dsoBundle.url(forResource: sourcesBundleName, withExtension: "bundle") else {
		throw Error.missingSourcesBundle(file: file, dsoBundleURL: dsoBundle.bundleURL, sourcesBundleName: sourcesBundleName)
	}
	guard let sourcesBundle = Bundle(url: sourcesBundleURL) else {
		throw Error.nonLoadableSourcesBundle(file: file, sourcesBundleURL: sourcesBundleURL)
	}
	let resourcePathComponents = resourcePath.components(separatedBy: "/")
	let subdirectory = resourcePathComponents.dropLast().joined(separator: "/")
	let resourceName = fileURL.deletingPathExtension().lastPathComponent
	let resourceExtension = fileURL.pathExtension
	guard let fileURLInBundle = sourcesBundle.url(forResource: resourceName, withExtension: resourceExtension, subdirectory: subdirectory) else {
		throw Error.missingFileInSourcesBundle(file: file, sourcesBundleURL: sourcesBundleURL, subdirectory: subdirectory)
	}
	return fileURLInBundle
}
