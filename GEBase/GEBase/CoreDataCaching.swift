//
//  CoreDataCaching.swift
//  GEBase
//
//  Created by Grigory Entin on 16/02/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import CoreData.NSManagedObjectContext
import CoreData.NSManagedObject

func associatedObjectRegeneratedAsNecessary<T>(obj obj: AnyObject!, key: UnsafePointer<Void>, type: T.Type) -> T {
	void(NSValue(pointer: unsafeAddressOf((obj))))
	guard let existingObject = objc_getAssociatedObject(obj, key) as! T! else {
		let newObject = (type as! NSObject.Type).init()
		objc_setAssociatedObject(obj, key, newObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return newObject as! T
	}
	return existingObject
}

func associatedObjectRegeneratedAsNecessary<T>(cls obj: AnyClass!, key: UnsafePointer<Void>, type: T.Type) -> T {
	void(NSValue(pointer: unsafeAddressOf((obj))))
	guard let existingObject = objc_getAssociatedObject(obj, key) as! T! else {
		let newObject = (type as! NSObject.Type).init()
		objc_setAssociatedObject(obj, key, newObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return newObject as! T
	}
	return existingObject
}

func ObjCEncode<T>(type: T.Type) -> String {
	if type is Int.Type {
		return String.fromCString((1 as NSNumber).objCType)!
	}
	return ""
}

let statefulValueCachesForObjectIDsAssoc = UnsafeMutablePointer<Void>.alloc(1)
let cachingEnabledMOCDidChangeObserverAssoc = UnsafeMutablePointer<Void>.alloc(1)
let cachingEnabledAssoc = UnsafeMutablePointer<Void>.alloc(1)
private let notificationCenter = NSNotificationCenter.defaultCenter()
extension NSManagedObjectContext {
	typealias _Self = NSManagedObjectContext
	var statefulValueCachesForObjectIDs: NSMutableDictionary! {
		get {
			return associatedObjectRegeneratedAsNecessary(obj: self, key: statefulValueCachesForObjectIDsAssoc, type: NSMutableDictionary.self)
		}
		set {
			precondition(nil == newValue)
			objc_setAssociatedObject(self, statefulValueCachesForObjectIDsAssoc, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
	public var cachingEnabled: Bool {
		get {
			return objc_getAssociatedObject(self, cachingEnabledAssoc) as! Bool? ?? false
		}
		set {
			objc_setAssociatedObject(self, cachingEnabledAssoc, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
			if newValue {
				let observer = notificationCenter.addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: self, queue: nil) { _ in
					self.statefulValueCachesForObjectIDs = nil
				}
				objc_setAssociatedObject(self, cachingEnabledMOCDidChangeObserverAssoc, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			}
			else {
				let observer = objc_getAssociatedObject(self, cachingEnabledMOCDidChangeObserverAssoc)
				notificationCenter.removeObserver(observer)
			}
		}
	}
}

class CacheRecord<T> : NSObject {
	let value: T
	init(value: T) {
		self.value = value
		super.init()
	}
}

let valueIMPsAssoc = UnsafeMutablePointer<Void>.alloc(1)
extension NSManagedObject {
	typealias _Self = NSManagedObject
	
	@objc var cachedIntValueStub: Int {
		return 0
	}
	@objc var cachedBoolValueStub: Bool {
		return true
	}
	@objc var cachedObjectValueStub: AnyObject! {
		return 0
	}

	var valuesCache: NSMutableDictionary? {
		let objectID = self.objectID
		guard !objectID.temporaryID else {
			return nil
		}
		precondition(!objectID.temporaryID)
		let statefulValueCachesForObjectIDs = self.managedObjectContext!.statefulValueCachesForObjectIDs
		guard let valuesCache = statefulValueCachesForObjectIDs[objectID] as! NSMutableDictionary? else {
			let newValuesCache = NSMutableDictionary()
			statefulValueCachesForObjectIDs[objectID] = newValuesCache
			return newValuesCache
		}
		return valuesCache
	}
}

func valueIMPsForClass(cls: AnyClass!) -> NSMutableDictionary! {
	return (associatedObjectRegeneratedAsNecessary(cls: (cls), key: valueIMPsAssoc, type: NSMutableDictionary.self))
}

extension NSManagedObject {
	@objc dynamic class func valueIMPs() -> NSMutableDictionary {
		return valueIMPsForClass(self)
	}
}

typealias IntPropertyGetter = @convention(c) (NSObject!, Selector) -> Int
typealias BoolPropertyGetter = @convention(c) (NSObject!, Selector) -> Bool
typealias AnyObjectPropertyGetter = @convention(c) (NSObject!, Selector) -> AnyObject?

func dispatchInt(p: UnsafePointer<Void>, _self: NSObject, _cmd: Selector) -> Int {
	return unsafeBitCast(p, IntPropertyGetter.self)(_self, _cmd)
}
func dispatchBool(p: UnsafePointer<Void>, _self: NSObject, _cmd: Selector) -> Bool {
	return unsafeBitCast(p, BoolPropertyGetter.self)(_self, _cmd)
}
func dispatchAnyObject(p: UnsafePointer<Void>, _self: NSObject, _cmd: Selector) -> AnyObject? {
	return (unsafeBitCast(p, AnyObjectPropertyGetter.self)(_self, _cmd)) as! AnyObject?
}

func cachedValueIMP<T>(_self: NSManagedObject, _ _cmd: Selector, _ _dispatch: (p: UnsafePointer<Void>, _self: NSManagedObject, _cmd: Selector) -> T) -> T {
	let selectorName = NSStringFromSelector(_cmd)
	_self.managedObjectContext!.processPendingChanges()
	let valuesCache = _self.valuesCache
	if let cacheRecord = valuesCache?[selectorName] as! CacheRecord<T>? {
		return cacheRecord.value
	}
	let cls = _self.dynamicType
	let valueIMPs = cls.valueIMPs()
	let valueIMP = (valueIMPs[selectorName] as! NSValue).pointerValue
	let value: T = _dispatch(p: valueIMP, _self: _self, _cmd: _cmd)
	if _self.managedObjectContext!.cachingEnabled {
		valuesCache?[selectorName] = CacheRecord(value: value)
	}
	return value
}

let cachedObjectValueIMP: @convention(c) (NSManagedObject!, Selector) -> AnyObject? = { _self, _cmd in
	cachedValueIMP(_self, _cmd, dispatchAnyObject)
}
let cachedIntValueIMP: @convention(c) (NSManagedObject!, Selector) -> Int = { _self, _cmd in
	cachedValueIMP(_self, _cmd, dispatchInt)
}
let cachedBoolValueIMP: @convention(c) (NSManagedObject!, Selector) -> Bool = { _self, _cmd in
	cachedValueIMP(_self, _cmd, dispatchBool)
}

public func cachePropertyWithName(cls: AnyClass!, name: String) {
	let sel = NSSelectorFromString(name)
	let getterMethod = class_getInstanceMethod($(cls), sel)
	let getterTypeEncoding = String.fromCString(method_getTypeEncoding(getterMethod))!
	let imp: IMP = {
		switch getterTypeEncoding {
		case String.fromCString(method_getTypeEncoding(class_getInstanceMethod(cls, NSSelectorFromString(NSManagedObject.self••{$0.cachedIntValueStub}))))!:
			return unsafeBitCast(cachedIntValueIMP, IMP.self)
		case String.fromCString(method_getTypeEncoding(class_getInstanceMethod(cls, NSSelectorFromString(NSManagedObject.self••{$0.cachedBoolValueStub}))))!:
			return unsafeBitCast(cachedBoolValueIMP, IMP.self)
		case String.fromCString(method_getTypeEncoding(class_getInstanceMethod(cls, NSSelectorFromString(NSManagedObject.self••{$0.cachedObjectValueStub}))))!:
			return unsafeBitCast(cachedObjectValueIMP, IMP.self)
		default:
			abort()
		}
	}()
	let method = class_getInstanceMethod(cls, sel)
	let typeEncoding = method_getTypeEncoding(method)
	let oldIMP = method_getImplementation(method)
	class_replaceMethod(cls, $(sel), $(imp), typeEncoding)
	let valueIMPs = cls.valueIMPs()
	assert(nil != oldIMP)
	valueIMPs[$(name)] = NSValue(pointer: unsafeBitCast($(oldIMP), UnsafePointer<Void>.self))
	assert(nil != cls.valueIMPs()[name])
}
