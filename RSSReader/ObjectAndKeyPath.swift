//
//  ObjectAndKeyPath.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public struct ObjectAndKeyPath {
	public let object: NSObject
	public let keyPath: String
	init(_ object: NSObject, _ keyPath: String) {
		self.object = object
		self.keyPath = keyPath
	}
}
