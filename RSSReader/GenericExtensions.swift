//
//  GenericExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func trace<T>(label: String, value: T, file: NSString = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) -> T {
	println("\(file.lastPathComponent), \(function).\(line): \(label): \(value)")
	return value
}

func void<T>(value: T) {
}

func URLQuerySuffixFromComponents(components: [String]) -> String {
	return components.reduce((prefix: "", suffix: "?")) {
		switch ($0) {
		case let (prefix, suffix):
			return ("\(prefix)\(suffix)\($1)", "&")
		}
	}.prefix
}
