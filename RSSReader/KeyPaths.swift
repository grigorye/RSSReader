//
//  KeyPaths.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

// MARK: -

private func recordKeyPath<T: NSObject, V>(fakeReturnValue: NSObject?, x: T, @noescape recorder: (T) -> V) -> String {
	let proxy = KeyPathRecordingProxy.alloc()
	proxy.fakeReturnValue = fakeReturnValue
	let savedObjectClass: AnyClass! = object_getClass(x)
	proxy.realObjectClass = savedObjectClass
	objc_setAssociatedObject(x, keyPathRecorderProxyAssociation, proxy, UInt(OBJC_ASSOCIATION_ASSIGN))
	object_setClass(x, KeyPathRecordingProxy.self)
	recorder(x)
	object_setClass(x, savedObjectClass)
	let keyPath = join(".", proxy.keyPathComponents! as! [String])
	return $(keyPath).$()
}

/// Specialization for the (Array-bound) code emitted by the compiler for any function call returning an Array.
public func instanceKeyPath<T: NSObject, V: AnyObject>(x: T, @noescape recorder: (T) -> [V]) -> String {
	return recordKeyPath([V](), x, recorder)
}

/// Specialization for the (String-bound) code emitted by the compiler for any function call returning a String.
public func instanceKeyPath<T: NSObject>(x: T, @noescape recorder: (T) -> String) -> String {
	return recordKeyPath("", x, recorder)
}

/// 
public func instanceKeyPath<T: NSObject, V>(x: T, @noescape recorder: (T) -> V) -> String {
	return recordKeyPath(nil, x, recorder)
}

// MARK: -

public struct ObjectAndKeyPath {
	public let object: NSObject
	public let keyPath: String
	init(objectAndKeyPath: ObjectAndKeyPath) {
		self.object = objectAndKeyPath.object
		self.keyPath = objectAndKeyPath.keyPath
	}
	init(_ object: NSObject, _ keyPath: String) {
		self.object = object
		self.keyPath = keyPath
	}
}

// MARK: - 

prefix operator • {}

public prefix func •<T: NSObject, V>(x: T) -> ((T) -> V) -> ObjectAndKeyPath {
	return { (@noescape recorder: (T) -> V) in
		return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
	}
}
