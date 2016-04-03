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

// MARK:-

private func dispatchGetter(p: IMP, _self: NSObject, _cmd: Selector) -> Int {
	typealias GetterType = @convention(c) (NSObject!, Selector) -> Int
	return unsafeBitCast(p, GetterType.self)(_self, _cmd)
}
private func dispatchSetter(p: IMP, _self: NSObject, _cmd: Selector, value: Int) {
	typealias SetterType = @convention(c) (NSObject!, Selector, Int) -> Void
	return unsafeBitCast(p, SetterType.self)(_self, _cmd, value)
}
private func dispatchGetter(p: IMP, _self: NSObject, _cmd: Selector) -> Bool {
	typealias GetterType = @convention(c) (NSObject!, Selector) -> Bool
	return unsafeBitCast(p, GetterType.self)(_self, _cmd)
}
private func dispatchSetter(p: IMP, _self: NSObject, _cmd: Selector, value: Bool) {
	typealias SetterType = @convention(c) (NSObject!, Selector, Bool) -> Void
	return unsafeBitCast(p, SetterType.self)(_self, _cmd, value)
}
private func dispatchGetter(p: IMP, _self: NSObject, _cmd: Selector) -> AnyObject? {
	typealias GetterType = @convention(c) (NSObject!, Selector) -> Bool
	return unsafeBitCast(p, GetterType.self)(_self, _cmd)
}
private func dispatchSetter(p: IMP, _self: NSObject, _cmd: Selector, value: AnyObject?) {
	typealias SetterType = @convention(c) (NSObject!, Selector, AnyObject?) -> Void
	return unsafeBitCast(p, SetterType.self)(_self, _cmd, value)
}

// MARK:-

private func cachedGetterImp<T>(_self: PropertyCacheable, _cmd: Selector, propertyName: String, dispatch: (p: IMP, _self: NSObject, _cmd: Selector) -> T, oldImp: IMP) -> T {
	let valuesCache = _self.actualizedValuesCache
	if let cacheRecord = valuesCache?[propertyName] as! CacheRecord<T>? {
		return cacheRecord.value
	}
	let value: T = dispatch(p: oldImp, _self: _self as! NSObject, _cmd: _cmd)
	if let valuesCache = valuesCache {
		valuesCache[propertyName] = CacheRecord(value: value)
	}
	return value
}

private func cachedSetterImp<T>(_self: PropertyCacheable, _cmd: Selector, propertyName: String, value: T, dispatch: (p: IMP, _self: NSObject, _cmd: Selector, value: T) -> Void, oldImp: IMP) {
	let valuesCache = _self.actualizedValuesCache
	dispatch(p: oldImp, _self: _self as! NSObject, _cmd: _cmd, value: value)
	if let valuesCache = valuesCache {
		valuesCache[propertyName] = nil
	}
}

// MARK:-

private func cachedGetterImpForPropertyTypeEncoding(propertyTypeEncoding: String, sel: Selector, propertyName: String, oldImp: IMP) -> IMP {
	switch propertyTypeEncoding {
	case objCEncode(Int.self):
		let block: @convention(block) (AnyObject!) -> Int = { _self in
			return cachedGetterImp(_self as! PropertyCacheable, _cmd: sel, propertyName: propertyName, dispatch: dispatchGetter, oldImp: oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	case objCEncode(Bool.self):
		let block: @convention(block) (AnyObject!) -> Bool = { _self in
			return cachedGetterImp(_self as! PropertyCacheable, _cmd: sel, propertyName: propertyName, dispatch: dispatchGetter, oldImp: oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	case objCEncode(NSObject.self), _ where propertyTypeEncoding.hasPrefix("@"):
		let block: @convention(block) (AnyObject!) -> AnyObject! = { _self in
			return cachedGetterImp(_self as! PropertyCacheable, _cmd: sel, propertyName: propertyName, dispatch: dispatchGetter, oldImp: oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	default:
		abort()
	}
}

private func cachedSetterImpForPropertyTypeEncoding(propertyTypeEncoding: String, sel: Selector, propertyName: String, oldImp: IMP) -> IMP {
	switch propertyTypeEncoding {
	case objCEncode(Int.self):
		let block: @convention(block) (AnyObject!, Int) -> Void = { _self, value in
			cachedSetterImp(_self as! PropertyCacheable, _cmd: sel, propertyName: propertyName, value: value, dispatch: dispatchSetter, oldImp: oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	case objCEncode(Bool.self):
		let block: @convention(block) (AnyObject!, Bool) -> Void = { _self, value in
			cachedSetterImp(_self as! PropertyCacheable, _cmd: sel, propertyName: propertyName, value: value, dispatch: dispatchSetter, oldImp: oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	case objCEncode(NSObject.self):
		let block: @convention(block) (AnyObject!, AnyObject!) -> Void = { _self, value in
			cachedSetterImp(_self as! PropertyCacheable, _cmd: sel, propertyName: propertyName, value: value, dispatch: dispatchSetter, oldImp: oldImp)
		}
		return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
	default:
		abort()
	}
}

// MARK:-

public func cachePropertyWithName(cls: AnyClass!, name propertyName: String) {
	let property = class_getProperty(cls, propertyName)
	let propertyTypeEncoding = objCPropertyAttributeValue(property, attributeName: "T")!
	do {
		let getterName = objCPropertyAttributeValue(property, attributeName: "G") ?? propertyName
		let getterSel = NSSelectorFromString(getterName)
		let getterMethod = class_getInstanceMethod($(cls), getterSel)
		let getterTypeEncoding = String.fromCString(method_getTypeEncoding(getterMethod))!
		let oldGetterImp = method_getImplementation(getterMethod)
		let cachedGetterImp = cachedGetterImpForPropertyTypeEncoding(propertyTypeEncoding, sel: getterSel, propertyName: propertyName, oldImp: oldGetterImp)
		let oldGetterImpAfterReplacingMethod = class_replaceMethod(cls, $(getterSel), $(cachedGetterImp), getterTypeEncoding)
		assert(oldGetterImp == oldGetterImpAfterReplacingMethod)
	}
	if nil == objCPropertyAttributeValue(property, attributeName: "R") {
		let setterName = objCPropertyAttributeValue(property, attributeName: "S") ?? objCDefaultSetterNameForPropertyName(propertyName)
		let setterSel = NSSelectorFromString(setterName)
		let setterMethod = class_getInstanceMethod($(cls), setterSel)
		let setterTypeEncoding = String.fromCString(method_getTypeEncoding(setterMethod))!
		let oldSetterImp = method_getImplementation(setterMethod)
		let cachedSetterImp = cachedSetterImpForPropertyTypeEncoding(propertyTypeEncoding, sel: setterSel, propertyName: propertyName, oldImp: oldSetterImp)
		let oldSetterImpAfterReplacingMethod = class_replaceMethod(cls, $(setterSel), $(cachedSetterImp), setterTypeEncoding)
		assert(oldSetterImp == oldSetterImpAfterReplacingMethod)
	}
}
