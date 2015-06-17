//
//  ObjectAndKeyPath-GeneratorFunction.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public func objectAndKeyPath<T: NSObject>(x: T!, recorder: (T!) -> ()) -> ObjectAndKeyPath {
	return ObjectAndKeyPath(x, instanceKeyPath(x, recorder: recorder))
}
