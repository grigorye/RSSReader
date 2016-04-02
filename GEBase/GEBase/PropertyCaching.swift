//
//  PropertyCaching.swift
//  GEBase
//
//  Created by Grigory Entin on 02.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public protocol PropertyCacheable {
	var actualizedValuesCache: NSMutableDictionary? { get }
}

private class CacheRecord<T> : NSObject {
	let value: T
	init(value: T) {
		self.value = value
		super.init()
	}
}

private func dispatchGetter(p: IMP, _self: NSObject, _cmd: Selector) -> Int {
	typealias GetterType = @convention(c) (NSObject!, Selector) -> Int
	return unsafeBitCast(p, GetterType.self)(_self, _cmd)
}
private func dispatchGetter(p: IMP, _self: NSObject, _cmd: Selector) -> Bool {
	typealias GetterType = @convention(c) (NSObject!, Selector) -> Bool
	return unsafeBitCast(p, GetterType.self)(_self, _cmd)
}
private func dispatchGetter(p: IMP, _self: NSObject, _cmd: Selector) -> AnyObject? {
	typealias GetterType = @convention(c) (NSObject!, Selector) -> Bool
	return unsafeBitCast(p, GetterType.self)(_self, _cmd)
}

private func cachedValueImp<T>(_self: PropertyCacheable, _ _cmd: Selector, _ _dispatch: (p: IMP, _self: NSObject, _cmd: Selector) -> T, _ oldIMP: IMP) -> T {
	let selectorName = NSStringFromSelector(_cmd)
	let valuesCache = _self.actualizedValuesCache
	if let cacheRecord = valuesCache?[selectorName] as! CacheRecord<T>? {
		return cacheRecord.value
	}
	let value: T = _dispatch(p: oldIMP, _self: _self as! NSObject, _cmd: _cmd)
	if let valuesCache = valuesCache {
		valuesCache[selectorName] = CacheRecord(value: value)
	}
	return value
}

private func cachedValueImpForMethodTypeEncoding(methodTypeEncoding: String, sel: Selector, oldImp: IMP) -> IMP {
	switch methodTypeEncoding {
	case objCGetterMethodEncoding(Int.self):
		let block: @convention(block) (AnyObject!) -> Int = { _self in
			return cachedValueImp(_self as! PropertyCacheable, sel, dispatchGetter, oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	case objCGetterMethodEncoding(Bool.self):
		let block: @convention(block) (AnyObject!) -> Bool = { _self in
			return cachedValueImp(_self as! PropertyCacheable, sel, dispatchGetter, oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	case objCGetterMethodEncoding(NSObject.self):
		let block: @convention(block) (AnyObject!) -> AnyObject! = { _self in
			return cachedValueImp(_self as! PropertyCacheable, sel, dispatchGetter, oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	default:
		abort()
	}
}

public func cachePropertyWithName(cls: AnyClass!, name: String) {
	let sel = NSSelectorFromString(name)
	let method = class_getInstanceMethod($(cls), sel)
	let methodTypeEncoding = String.fromCString(method_getTypeEncoding(method))!
	let oldImp = method_getImplementation(method)
	let cachedValueImp = cachedValueImpForMethodTypeEncoding(methodTypeEncoding, sel: sel, oldImp: oldImp)
	let oldImpAfterReplaceMethod = class_replaceMethod(cls, $(sel), $(cachedValueImp), methodTypeEncoding)
	assert(oldImp == oldImpAfterReplaceMethod)
}
