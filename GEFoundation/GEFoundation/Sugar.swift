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
public func …<T: AnyObject>(obj: T, initialize: (T) throws -> Void) rethrows -> T {
	try initialize(obj)
	return obj
}
public func …<T: Any>(value: T, initialize: (inout T) throws -> Void) rethrows -> T {
	var valueCopy = value
	try initialize(&valueCopy)
	return valueCopy
}

/**
    Substitute for `Void` in `static let initializeOnce: Void = {...}`.
	
	`Void` breaks LLDB interactions when `initializeOnce` is visible as below:

        (lldb) p tableView.estimatedRowHeight
        error: Couldn't materialize: couldn't get the value of initializeOnce: extracting data from value failed
        error: errored out in DoExecute, couldn't PrepareToExecuteJITExpression
*/
public typealias Ignored = Int
