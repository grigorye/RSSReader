//
//  ObjectAndKeyPath.swift
//  GEBase
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public struct ObjectAndKeyPath {
	public let object: NSObject
	public let keyPath: String
}

public func objectAndKeyPath(_ object: NSObject, _ keyPath: String) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(object: object, keyPath: keyPath)
}

infix operator •
public func •(object: NSObject, keyPath: String) -> ObjectAndKeyPath {
	return objectAndKeyPath(object, keyPath)
}
