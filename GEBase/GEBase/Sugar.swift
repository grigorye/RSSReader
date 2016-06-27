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

infix operator … {}
public func …<T: AnyObject>(obj: T, initialize: @noescape (T) -> Void) -> T {
	initialize(obj)
	return obj
}
public func …<T: Any>(value: T, initialize: @noescape (inout value: T) -> Void) -> T {
	var valueCopy = value
	initialize(value: &valueCopy)
	return valueCopy
}
