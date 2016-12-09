//
//  ModuleExports-GEFoundation.swift
//  GEFoundation
//
//  Created by Grigory Entin on 09.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation

infix operator …

@discardableResult
internal func …<T: AnyObject>(obj: T, initialize: (T) throws -> Void) rethrows -> T {
	return try with(obj, initialize)
}

internal func …<T: Any>(value: T, initialize: (inout T) throws -> Void) rethrows -> T {
	return try with(value, initialize)
}

// MARK: -

typealias KVOCompliantUserDefaults = GEFoundation.KVOCompliantUserDefaults
typealias ProgressEnabledURLSessionTaskGenerator = GEFoundation.ProgressEnabledURLSessionTaskGenerator
typealias URLSessionTaskGeneratorError = GEFoundation.URLSessionTaskGeneratorError

typealias Ignored = GEFoundation.Ignored
typealias Handler = GEFoundation.Handler
typealias KVOBinding = GEFoundation.KVOBinding

var defaults: KVOCompliantUserDefaults {
	return GEFoundation.defaults
}

var _1: Bool { return GEFoundation._1 }
var _0: Bool { return GEFoundation._0 }

var progressEnabledURLSessionTaskGenerator: ProgressEnabledURLSessionTaskGenerator {
	return GEFoundation.progressEnabledURLSessionTaskGenerator
}

infix operator •

internal func •(object: NSObject, keyPath: String) -> ObjectAndKeyPath {
	return GEFoundation.objectAndKeyPath(object, keyPath)
}

internal func nilForNull(_ object: Any) -> Any? {
	return GEFoundation.nilForNull(object)
}

internal func filterObjectsByType<T>(_ objects: [Any]) -> [T] {
	return GEFoundation.filterObjectsByType(objects)
}

internal func invoke(handler: Handler) {
	return GEFoundation.invoke(handler: handler)
}
