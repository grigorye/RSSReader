//
//  Sugar.swift
//  GEBase
//
//  Created by Grigory Entin on 27/06/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

//
// The idea is borrowed from https://github.com/devxoul/Then
//

infix operator …
@discardableResult
public func …<T: AnyObject>(obj: T, initialize: (T) -> Void) -> T {
	initialize(obj)
	return obj
}
public func …<T: Any>(value: T, initialize: (inout T) -> Void) -> T {
	var valueCopy = value
	initialize(&valueCopy)
	return valueCopy
}
