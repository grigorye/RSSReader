//
//  GenericExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public func void<T>(value: T) {
}

public typealias Handler = () -> Void

public func invoke(handler: Handler) {
	handler()
}

public func URLQuerySuffixFromComponents(components: [String]) -> String {
	return components.reduce((prefix: "", suffix: "?")) {
		let (prefix, suffix) = $0
		return ("\(prefix)\(suffix)\($1)", "&")
	}.prefix
}

public func filterObjectsByType<T>(objects: [AnyObject]) -> [T] {
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

public func nilForNull(object: AnyObject) -> AnyObject? {
	if (object as! NSObject) == NSNull() {
		return nil
	}
	else {
		return object
	}
}

extension CollectionType {
	public var onlyElement: Self.Generator.Element? {
		precondition(self.count <= 1)
		return self.first
	}
}
