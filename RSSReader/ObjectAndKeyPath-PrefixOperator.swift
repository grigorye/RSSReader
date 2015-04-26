//
//  KeyPaths-PrefixOperator.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

prefix operator •• {}

public prefix func ••<T: NSObject>(x: T) -> ((T!) -> ()) -> ObjectAndKeyPath {
	return { (recorder: (T!) -> ()) in
		return ObjectAndKeyPath(x, instanceKeyPath(x, recorder))
	}
}
