//
//  KeyPaths.swift
//  Base
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public func recordedInstanceKeyPath<T: NSObject>(x: T?, recorder: ((T!) -> ())!) -> String {
	let proxy = KeyPathRecordingProxy.newProxy()
	recorder(unsafeBitCast(proxy, T.self))
	let keyPath = proxy.keyPathComponents.joinWithSeparator(".")
	return $(keyPath).$(0)
}

public func instanceKeyPath<T: NSObject>(x: T?, recorder: (() -> String)!) -> String {
	let swiftQuery = recorder()
	let keyPath = String(swiftQuery.characters.filter { $0 != "!" && $0 != "?" })
	return $(keyPath).$(0)
}
