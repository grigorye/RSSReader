//
//  Descriptions.swift
//  GEBase
//
//  Created by Grigory Entin on 29/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func description(value: NSIndexPath) -> String {
	var components = [String]()
	for i in 0 ..< value.length {
		components += ["\(value.indexAtPosition(i))"]
	}
	return components.joinWithSeparator(", ")
}

func trace(value: NSIndexPath, startLocation: SourceLocation, endLocation: SourceLocation) -> NSIndexPath {
	traceString(description(value), location: startLocation, lastLocation: endLocation)
	return value
}
