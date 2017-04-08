//
//  KVOCompliantUserDefaults.swift
//  GEBase
//
//  Created by Grigory Entin on 15/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

public let defaults = KVOCompliantUserDefaults()

private let objcEncode_Bool = String(validatingUTF8: NSNumber(value: true).objCType)!
private let objcEncode_Int = "i"
private let objcEncode_Long = "l"
private let objcEncode_LongLong = "q"
private let objcEncode_C99Bool = "B"
private let objcEncode_AnyObject = "@"

// MARK: -

typealias _Self = KVOCompliantUserDefaults

private let objectValueIMP: @convention(c) (_Self, Selector) -> AnyObject? = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let value = _self.values[propertyName]
	•(propertyName)
	return (value)
}
private let setObjectValueIMP: @convention(c) (_Self, Selector, NSObject?) -> Void = { _self, _cmd, value in
	let defaultName = _Self.defaultNameForSelector(_cmd)
	_self.defaults.set(value, forKey:(defaultName))
	_self.values[defaultName] = value
}
private let boolValueIMP: @convention(c) (_Self, Selector) -> Bool = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let valueObject = _self.values[propertyName]
	let value: Bool = {
		switch valueObject {
		case let numberValue as NSNumber:
			return numberValue.boolValue
		case let stringValue as NSString:
			return stringValue.boolValue
		case nil:
			return false
		default:
			abort()
		}
	}()
	•(propertyName)
	return (value)
}
private let longValueIMP: @convention(c) (_Self, Selector) -> CLong = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let valueObject = _self.values[propertyName]
	let value: Int = {
		switch valueObject {
		case let numberValue as NSNumber:
			return numberValue.intValue
		case let stringValue as NSString:
			return stringValue.integerValue
		case nil:
			return 0
		default:
			abort()
		}
	}()
	•(propertyName)
	return (value)
}
private let longLongValueIMP: @convention(c) (_Self, Selector) -> CLongLong = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let valueObject = _self.values[propertyName]
	let value: CLongLong = {
		switch valueObject {
		case let numberValue as NSNumber:
			return numberValue.int64Value
		case let stringValue as NSString:
			return stringValue.longLongValue
		case nil:
			return 0
		default:
			abort()
		}
	}()
	•(propertyName)
	return (value)
}

private let setBoolValueIMP: @convention(c) (_Self, Selector, Bool) -> Void = { _self, _cmd, value in
	let propertyName = NSStringFromSelector(_cmd)
	$(propertyName)
	_self.defaults.set(value, forKey: propertyName)
	_self.values[propertyName] = NSNumber(value: value)
}
private let setLongValueIMP: @convention(c) (_Self, Selector, CLong) -> Void = { _self, _cmd, value in
	let propertyName = NSStringFromSelector(_cmd)
	$(propertyName)
	_self.defaults.set(value, forKey: propertyName)
	_self.values[propertyName] = NSNumber(value: value)
}
private let setLongLongValueIMP: @convention(c) (_Self, Selector, CLongLong) -> Void = { _self, _cmd, value in
	let propertyName = NSStringFromSelector(_cmd)
	$(propertyName)
	_self.defaults.set(Int(value), forKey: propertyName)
	_self.values[propertyName] = NSNumber(value: value)
}

extension KVOCompliantUserDefaults {
	typealias _Self = KVOCompliantUserDefaults

	static func defaultNameForSelector(_ sel: Selector) -> String {
		let selName = NSStringFromSelector(sel)
		let propertyInfo = getterAndSetterMap[selName]!
		•(propertyInfo)
		let defaultName = propertyInfo.name
		return defaultName
	}

	// MARK: -

	static let (propertyInfoMap, getterAndSetterMap): ([String : PropertyInfo], [String : PropertyInfo]) = {
		var propertyInfoMap = [String : PropertyInfo]()
		var getterAndSetterMap = [String : PropertyInfo]()
		var propertyCount = UInt32(0)
		let propertyList = class_copyPropertyList(KVOCompliantUserDefaults.self, &propertyCount)!
		for i in 0..<Int(propertyCount) {
			let property = propertyList[i]!
			let propertyInfo = PropertyInfo(property: property)
			let attributesDictionary = propertyInfo.attributesDictionary
			let propertyName = propertyInfo.name
			let customSetterName = attributesDictionary["S"]
			let customGetterName = attributesDictionary["G"]
			let defaultGetterName = propertyName
			let defaultSetterName = objCDefaultSetterName(forPropertyName: propertyName)
			getterAndSetterMap[customGetterName ?? defaultGetterName] = propertyInfo
			getterAndSetterMap[customSetterName ?? defaultSetterName] = propertyInfo
			propertyInfoMap[propertyName] = propertyInfo
		}
		free(propertyList)
		return (propertyInfoMap, getterAndSetterMap)
	}()

	static func isDefaultName(_ name: String) -> Bool {
		return !["values", "defaults"].contains(name)
	}
}

public class KVOCompliantUserDefaults : NSObject {
	var values = [String : NSObject]()
	let defaults = UserDefaults.standard

	func synchronizeValues() {
		for (propertyName, propertyInfo) in _Self.propertyInfoMap {
			let defaults = self.defaults
			guard _Self.isDefaultName(propertyInfo.name) else {
				continue
			}
			let oldValue = values[propertyName]
			let newValue = defaults.object(forKey: propertyName) as! NSObject?
			guard oldValue != newValue else {
				continue
			}
			guard true != (oldValue?.isEqual(newValue)) else {
				continue
			}
			self.willChangeValue(forKey: propertyName)
			self.values[propertyName] = newValue
			self.didChangeValue(forKey: propertyName)
		}
	}

	public override static func resolveInstanceMethod(_ sel: Selector) -> Bool {
		let selName = NSStringFromSelector(sel)
		guard let propertyInfo = getterAndSetterMap[selName] else {
			return super.resolveInstanceMethod(sel)
		}
		•(propertyInfo)
		let isSetter = selName.hasSuffix(":")
		let valueTypeEncoded = propertyInfo.valueTypeEncoded
		let methodIMP: IMP = {
			switch valueTypeEncoded {
			case objcEncode_Bool, objcEncode_C99Bool:
				return isSetter ? unsafeBitCast(setBoolValueIMP, to: IMP.self) : unsafeBitCast(boolValueIMP, to: IMP.self)
			case objcEncode_Long, objcEncode_Int:
				return isSetter ? unsafeBitCast(setLongValueIMP, to: IMP.self) : unsafeBitCast(longValueIMP, to: IMP.self)
			case objcEncode_LongLong:
				return isSetter ? unsafeBitCast(setLongLongValueIMP, to: IMP.self) : unsafeBitCast(longLongValueIMP, to: IMP.self)
			case objcEncode_AnyObject:
				return isSetter ? unsafeBitCast(setObjectValueIMP, to: IMP.self) : unsafeBitCast(objectValueIMP, to: IMP.self)
			default:
				fatalError("\(L(valueTypeEncoded))")
			}
		}()
		let types = isSetter ? "v@:\(valueTypeEncoded)" : "\(valueTypeEncoded)@:"
		types.withCString { typesCString in
			_ = class_addMethod(self, sel, methodIMP, typesCString)
		}
		return true
	}
	
	// MARK: -
	
	var handlingDidChangeNotification = false
	
	func defaultsDidChange(_ notification: Notification) {
		guard !handlingDidChangeNotification else {
			return
		}
		handlingDidChangeNotification = true; defer {handlingDidChangeNotification = false }
		defaults.synchronize()
		synchronizeValues()
	}
	
	// MARK: -
	
	var scheduledForDeinit = ScheduledHandlers()
	deinit {
		scheduledForDeinit.perform()
	}
	
	public override init () {
		super.init()
		let notificationCenter = NotificationCenter.default
		let observer = notificationCenter.addObserver(forName: UserDefaults.didChangeNotification, object:nil, queue:nil) { [unowned self] notification in
			self.defaultsDidChange(notification)
		}
		scheduledForDeinit += [{
			notificationCenter.removeObserver(observer)
		}]
		synchronizeValues()
	}
}
