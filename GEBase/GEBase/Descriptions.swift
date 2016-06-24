//
//  Descriptions.swift
//  GEBase
//
//  Created by Grigory Entin on 29/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func description(value: NSIndexPath) -> String {
	let components = (0 ..< value.length).map {"\(value.index(atPosition: $0))"}
	return components.joined(separator: ", ")
}
