//
//  KeyPaths.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

// MARK: -

private func recordKeyPath<T: NSObject, V>(valueClass: AnyClass!, x: T?, @noescape recorder: (T) -> V) -> String {
	let proxy = KeyPathRecordingProxy.alloc()
	proxy.valueClass = valueClass
	let proxifiedX = proxy as! T
	recorder(proxifiedX)
	let keyPath = join(".", proxy.keyPathComponents! as! [String])
	return $(keyPath).$()
}

/// Specialization for the (Array-bound) code emitted by the compiler for any function call returning an Array.
public func instanceKeyPath<T: NSObject, V: AnyObject>(x: T?, @noescape recorder: (T) -> [V]) -> String {
	return recordKeyPath(NSArray.self, x, recorder)
}

/// Specialization for the (String-bound) code emitted by the compiler for any function call returning a String.
public func instanceKeyPath<T: NSObject>(x: T?, @noescape recorder: (T) -> String) -> String {
	return recordKeyPath(NSString.self, x, recorder)
}

/// Specialization for the (String-bound) code emitted by the compiler for any function call returning an optional String.
public func instanceKeyPath<T: NSObject>(x: T?, @noescape recorder: (T) -> Optional<String>) -> String {
	return recordKeyPath(NSString.self, x, {recorder($0)!})
}

/// Generic implementation.
public func instanceKeyPath<T: NSObject, V>(x: T?, @noescape recorder: (T) -> V) -> String {
	return recordKeyPath(nil, x, recorder)
}
