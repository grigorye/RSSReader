//
//  Descriptions.swift
//  RSSReader
//
//  Created by Grigory Entin on 29/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func description<T: NSIndexPath>(value: NSIndexPath) -> String {
	var components = [String]()
	for var i = 0; i < value.length; ++i {
		components += ["\(value.indexAtPosition(i))"]
	}
	return join(", ", components)
}

func trace<T: NSIndexPath>(label: String, value: NSIndexPath, file: NSString = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) -> NSIndexPath {
	traceString(label, description(value), file: file, line: line, function: function)
	return value
}
