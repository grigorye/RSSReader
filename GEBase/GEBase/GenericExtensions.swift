//
//  GenericExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public typealias Handler = () -> Void

public func invoke(handler: Handler) {
	handler()
}

public func URLQuerySuffix(fromComponents components: [String]) -> String {
	return components.reduce((prefix: "", suffix: "?")) {
		let (prefix, suffix) = $0
		return ("\(prefix)\(suffix)\($1)", "&")
	}.prefix
}

public func filterObjectsByType<T>(_ objects: [AnyObject]) -> [T] {
	let filteredObjects = objects.reduce([T]()) {
		if let x = $($1) as? T {
			return $0 + [x]
		}
		else {
			return $0
		}
	}
	return filteredObjects
}

public func nilForNull(_ object: AnyObject) -> AnyObject? {
	if (object as! NSObject) == NSNull() {
		return nil
	}
	else {
		return object
	}
}

extension Collection {
	public var onlyElement: Self.Iterator.Element? {
		precondition(self.count <= 1)
		return self.first
	}
}
