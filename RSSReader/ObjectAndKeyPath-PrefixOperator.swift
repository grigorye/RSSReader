//
//  KeyPaths-PrefixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

prefix operator •• {}

public prefix func ••<T: NSObject, V: AnyObject>(x: T) -> ((T) -> [V]) -> ObjectAndKeyPath {
	return { (@noescape recorder: (T) -> [V]) in
		return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
	}
}
public prefix func ••<T: NSObject, V>(x: T) -> ((T) -> String) -> ObjectAndKeyPath {
	return { (@noescape recorder: (T) -> String) in
		return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
	}
}
public prefix func ••<T: NSObject, V>(x: T) -> ((T) -> V) -> ObjectAndKeyPath {
	return { (@noescape recorder: (T) -> V) in
		return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
	}
}
