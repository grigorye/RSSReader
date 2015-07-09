//
//  KeyPaths.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

#if false
public func instanceKeyPath<T: NSObject>(x: T?, recorder: ((T!) -> Void)!) -> String {
	let keyPath = recordKeyPath { x in
		recorder(x as! T!)
	}
	return $(keyPath).$(0)
}
#else
public func instanceKeyPath<T: NSObject>(x: T?, recorder: (() -> String)!) -> String {
	let swiftQuery = recorder()
	let keyPath = String(swiftQuery.characters.filter { $0 != "!" && $0 != "?" })
	return $(keyPath).$(0)
}
#endif
