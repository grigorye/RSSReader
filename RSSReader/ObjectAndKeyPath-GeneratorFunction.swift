//
//  ObjectAndKeyPath-GeneratorFunction.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public func xxx<T: NSObject, V: AnyObject>(x: T!, @noescape recorder: (T!) -> [V]) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
}
public func xxx<T: NSObject>(x: T!, @noescape recorder: (T!) -> String) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
}
public func xxx<T: NSObject>(x: T!, @noescape recorder: (T!) -> Optional<String>) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
}
public func xxx<T: NSObject, V>(x: T!, @noescape recorder: (T!) -> V) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
}
