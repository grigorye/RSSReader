//
//  main.swift
//  CwlUtilsConcat
//
//  Created by Matt Gallagher on 2017/06/24.
//  Copyright © 2017 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

extension FileHandle: TextOutputStream { public func write(_ string: String) { string.data(using: .utf8).map { write($0) } } }
var stdErrStream = FileHandle.standardError

guard ProcessInfo.processInfo.arguments.count >= 4 else {
	print("CwlUtilsConcat is a simple tool for concatenating Swift files from various Cocoa with Love frameworks into a single file, as an alternative to linking a separate framework or library. Due to hard-coded matching and relocation of copyright headers, this tool is not suitable for use with code from other sources or authors.", to: &stdErrStream)
	print("usage: CwlUtilsConcat (internal|public) outputFile [-m introMessage] [-t text | -x excludedPath | inputFileOrDirPath]+", to: &stdErrStream)
	exit(1)
}

class GetLineIterator: Sequence, IteratorProtocol {
	let file: UnsafeMutablePointer<FILE>
	init?(_ path: String) {
		guard let file = fopen(path, "r") else { return nil }
		self.file = file
	}
	
	func next() -> String? {
		var line: UnsafeMutablePointer<Int8>? = nil
		var linecap: Int = 0
		if getline(&line, &linecap, file) > 0, let l = line {
			defer { free(line) }
			return String(cString: l)
		}
		return nil
	}
	
	deinit {
		fclose(file)
	}
}

enum ProcessingError: Error {
	case fileNotFound(String)
	case couldntOpenFile(String)
	case cantCreateOutputFile(String)
	case unknownAuthorship(String)
	case noInput
}

let publicAndOpenPattern = try! NSRegularExpression(pattern: "(^|\t|[^,] )(public |open )", options: [])
func stripPublicAndOpen(_ line: String) -> String {
	return publicAndOpenPattern.stringByReplacingMatches(in:line, range: NSMakeRange(0, line.count), withTemplate: "$1")
}

let authorPattern = try! NSRegularExpression(pattern: "^//  Copyright © .... Matt Gallagher.*\\. All rights reserved\\.$", options: [])
func appendFile(_ filePath: String, output: FileHandle, wantInternal: Bool) throws {
	guard let lineIterator = GetLineIterator(filePath) else { throw ProcessingError.couldntOpenFile(filePath) }
	var initialHeaderBlock = true
	var lineCount = 0
	for line in lineIterator {
		lineCount += 1
		if initialHeaderBlock {
			if line.hasPrefix("//") {
				if lineCount == 6 {
					if authorPattern.firstMatch(in: line, range: NSMakeRange(0, line.count)) == nil {
						throw ProcessingError.unknownAuthorship(filePath)
					}
				}
				continue
			}
			initialHeaderBlock = false
		}
		output.write(wantInternal ? stripPublicAndOpen(line) : line)
	}
}

enum Flag {
	case message
	case text
	case exclude
	case none
}

enum Include {
	case filePath(String)
	case text(String)
}

do {
	let wantInternal = ProcessInfo.processInfo.arguments[1] == "internal"
	
	let outputPath = ProcessInfo.processInfo.arguments[2]
	guard FileManager.default.createFile(atPath: outputPath, contents: nil, attributes: nil) else { throw ProcessingError.cantCreateOutputFile(outputPath) }
	let output = try FileHandle(forWritingTo: URL(fileURLWithPath: outputPath))
	
	var insertedFileCount = 0
	var srcDirs = [(String, Int)]()
	var includes = [Include]()
	var excludeFiles = Set<String>()
	var flag = Flag.none
	var message = ""
	var commonString = nil as String?
	var useCommonString = false
	for arg in ProcessInfo.processInfo.arguments[3..<ProcessInfo.processInfo.arguments.count] {
		switch arg {
		case "-x": flag = .exclude; continue
		case "-m": flag = .message; continue
		case "-t": flag = .text; continue
		default: break
		}
		switch flag {
		case .exclude:
			excludeFiles.insert(arg)
			flag = .none
			continue
		case .message:
			message = arg
			flag = .none
			continue
		case .text:
			includes.append(.text(arg))
			flag = .none
			continue
		default: break
		}
		
		var isDir: ObjCBool = false
		guard FileManager.default.fileExists(atPath: arg, isDirectory: &isDir) else { throw ProcessingError.fileNotFound(arg) }
		var appendedPath = arg
		if isDir.boolValue {
			srcDirs.append((arg, includes.count))
			if !arg.hasSuffix("/") {
				appendedPath = appendedPath + "/"
			}
		} else {
			includes.append(.filePath(arg))
		}
		
		if let cs = commonString {
			commonString = String(zip(cs, appendedPath).prefix { $0.0 == $0.1 }.map { $0.0 })
			if commonString != arg {
				useCommonString = true
			}
		} else {
			commonString = appendedPath
		}
	}
	
	guard let cs = commonString else { throw ProcessingError.noInput }
	let commonCount = cs.count
	
	for (dirPath, index) in srcDirs {
		guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: dirPath), includingPropertiesForKeys: []) else { throw ProcessingError.fileNotFound(dirPath) }
		for file in enumerator {
			let fileUrl = file as! URL
			if excludeFiles.contains(fileUrl.path) {
				if !fileUrl.isFileURL {
					enumerator.skipDescendants()
				}
				continue
			}
			if fileUrl.pathExtension != "swift" { continue }
			includes.insert(.filePath(fileUrl.path), at: index + insertedFileCount)
			insertedFileCount += 1
		}
	}
	
	output.write(message)
	output.write("//  Copyright © 2015-2018 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.\n")
	output.write("//\n")
	output.write("//  Permission to use, copy, modify, and/or distribute this software for any\n")
	output.write("//  purpose with or without fee is hereby granted, provided that the above\n")
	output.write("//  copyright notice and this permission notice appear in all copies.\n")
	output.write("//\n")
	output.write("//  THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL WARRANTIES\n")
	output.write("//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF\n")
	output.write("//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY\n")
	output.write("//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES\n")
	output.write("//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN\n")
	output.write("//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR\n")
	output.write("//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.\n")
	output.write("//\n")
	output.write("//  This file was generated by the CwlUtilsConcat tool on \(NSDate()) from the following files:\n//\n")
	for include in includes {
		switch include {
		case .text: continue
		case .filePath(let filePath):
			let minusCommon = useCommonString ? String(filePath.dropFirst(commonCount)) : NSString(string: filePath).lastPathComponent
			output.write("//    \(minusCommon)\n")
		}
	}
	output.write("//\n\n")
		
	for include in includes {
		switch include {
		case .text(let t):
			output.write(t)
			output.write("\n")
		case .filePath(let filePath):
			output.write("\n// MARK: ### \(NSString(string: filePath).lastPathComponent) ###\n")
			try appendFile(filePath, output: output, wantInternal: wantInternal)
		}
	}
} catch {
	print("Failed: \(error)", to: &stdErrStream)
	exit(1)
}

