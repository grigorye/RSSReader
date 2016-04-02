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

typealias IntPropertyGetter = @convention(c) (NSObject!, Selector) -> Int
typealias BoolPropertyGetter = @convention(c) (NSObject!, Selector) -> Bool
typealias AnyObjectPropertyGetter = @convention(c) (NSObject!, Selector) -> AnyObject?

func dispatchInt(p: IMP, _self: NSObject, _cmd: Selector) -> Int {
	return unsafeBitCast(p, IntPropertyGetter.self)(_self, _cmd)
}
func dispatchBool(p: IMP, _self: NSObject, _cmd: Selector) -> Bool {
	return unsafeBitCast(p, BoolPropertyGetter.self)(_self, _cmd)
}
func dispatchAnyObject(p: IMP, _self: NSObject, _cmd: Selector) -> AnyObject? {
	return unsafeBitCast(p, AnyObjectPropertyGetter.self)(_self, _cmd)
}

func cachedValueIMP<T>(_self: NSManagedObject, _ _cmd: Selector, _ _dispatch: (p: IMP, _self: NSManagedObject, _cmd: Selector) -> T, _ oldIMP: IMP) -> T {
	let selectorName = NSStringFromSelector(_cmd)
	_self.managedObjectContext!.processPendingChanges()
	let valuesCache = _self.valuesCache
	if let cacheRecord = valuesCache?[selectorName] as! CacheRecord<T>? {
		return cacheRecord.value
	}
	let value: T = _dispatch(p: oldIMP, _self: _self, _cmd: _cmd)
	if _self.managedObjectContext!.cachingEnabled {
		valuesCache?[selectorName] = CacheRecord(value: value)
	}
	return value
}

public func cachePropertyWithName(cls: AnyClass!, name: String) {
	let sel = NSSelectorFromString(name)
	let method = class_getInstanceMethod($(cls), sel)
	let methodTypeEncoding = String.fromCString(method_getTypeEncoding(method))!
	let oldImp = method_getImplementation(method)
	let imp: IMP = {
		switch methodTypeEncoding {
		case String.fromCString(method_getTypeEncoding(class_getInstanceMethod(cls, NSSelectorFromString(NSManagedObject.self••{$0.cachedIntValueStub}))))!:
			let block: @convention(block) (AnyObject!) -> Int = { _self in
				return cachedValueIMP(_self as! NSManagedObject, sel, dispatchInt, oldImp)
			}
			return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
		case String.fromCString(method_getTypeEncoding(class_getInstanceMethod(cls, NSSelectorFromString(NSManagedObject.self••{$0.cachedBoolValueStub}))))!:
			let block: @convention(block) (AnyObject!) -> Bool = { _self in
				return cachedValueIMP(_self as! NSManagedObject, sel, dispatchBool, oldImp)
			}
			return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
		case String.fromCString(method_getTypeEncoding(class_getInstanceMethod(cls, NSSelectorFromString(NSManagedObject.self••{$0.cachedObjectValueStub}))))!:
			let block: @convention(block) (AnyObject!) -> AnyObject! = { _self in
				return cachedValueIMP(_self as! NSManagedObject, sel, dispatchAnyObject, oldImp)
			}
			return imp_implementationWithBlock(unsafeBitCast(block, AnyObject.self))
		default:
			abort()
		}
	}()
	let oldImpAfterReplaceMethod = class_replaceMethod(cls, $(sel), $(imp), methodTypeEncoding)
	assert(oldImp == oldImpAfterReplaceMethod)
}
