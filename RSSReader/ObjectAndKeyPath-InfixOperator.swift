//
//  ObjectAndKeyPath-InfixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

infix operator • {}
public func •<T: NSObject>(x: T!, recorder: (T!) -> ()) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
}

infix operator •• {}
public func ••<T: NSObject>(x: T, recorder: (T!) -> ()) -> String {
	return instanceKeyPath(x, recorder)
}
public func ••<T: NSObject>(cls: T.Type, recorder: (T!) -> ()) -> String {
	let x = Optional<T>()
	return instanceKeyPath(x, recorder)
}
