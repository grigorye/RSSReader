//
//  KeyPaths.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public func instanceKeyPath<T: NSObject>(x: T?, recorder: ((T!) -> Void)!) -> String {
	let keyPath = recordKeyPath { x in
		recorder(x as! T!)
	}
	return $(keyPath).$(0)
}
