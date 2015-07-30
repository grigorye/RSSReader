//
//  ObjectAndKeyPath-InfixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

infix operator • {}
#if false
/// Returns object and key path given an object and key path recorder.
public func •<T: NSObject>(x: T!, recorder: (T!) -> ()) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder: recorder))
}
#else
public func •<T: NSObject>(x: T!, recorder: () -> String) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder: recorder))
}
#endif

infix operator •• {}
#if false
/// Returns key path recorded given a sample object (the object value does not matter).
public func ••<T: NSObject>(x: T!, recorder: (T!) -> ()) -> String {
	return instanceKeyPath(x, recorder: recorder)
}
/// Returns key path recorded given a class.
public func ••<T: NSObject>(cls: T.Type, recorder: (T!) -> ()) -> String {
	let x = Optional<T>()
	return instanceKeyPath(x, recorder: recorder)
}
#else
public func ••<T: NSObject>(x: T!, recorder: () -> String) -> String {
	return instanceKeyPath(x, recorder: recorder)
}
public func ••<T: NSObject>(cls: T.Type, recorder: () -> String) -> String {
	let x = Optional<T>()
	return instanceKeyPath(x, recorder: recorder)
}
#endif
