//
//  KVOCompliantUserDefaults.swift
//  GEBase
//
//  Created by Grigory Entin on 15/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

private let objcEncode_Bool = String(validatingUTF8: NSNumber(value: true).objCType)!
private let objcEncode_Int = "i"
private let objcEncode_Long = "l"
private let objcEncode_LongLong = "q"
private let objcEncode_C99Bool = "B"
private let objcEncode_AnyObject = "@"

// MARK: -

extension KVOCompliantUserDefaults {
	typealias _Self = KVOCompliantUserDefaults

	static private func defaultNameForSelector(_ sel: Selector) -> String {
		let selName = NSStringFromSelector(sel)
		let propertyInfo = getterAndSetterMap[selName]!
		•(propertyInfo)
		let defaultName = propertyInfo.name
		return defaultName
	}
	static private let objectValueIMP: @convention(c) (_Self, Selector) -> AnyObject? = { _self, _cmd in
		let propertyName = NSStringFromSelector(_cmd)
		let value = _self.values[propertyName]
		•(propertyName)
		return (value)
	}
	static private let setObjectValueIMP: @convention(c) (_Self, Selector, NSObject?) -> Void = { _self, _cmd, value in
		let defaultName = _Self.defaultNameForSelector(_cmd)
		_self.defaults.set(value, forKey:(defaultName))
		_self.values[defaultName] = value
	}
	static private let boolValueIMP: @convention(c) (_Self, Selector) -> Bool = { _self, _cmd in
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
	static private let longValueIMP: @convention(c) (_Self, Selector) -> CLong = { _self, _cmd in
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
	static private let longLongValueIMP: @convention(c) (_Self, Selector) -> CLongLong = { _self, _cmd in
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

	static private let setBoolValueIMP: @convention(c) (_Self, Selector, Bool) -> Void = { _self, _cmd, value in
		let propertyName = NSStringFromSelector(_cmd)
		$(propertyName)
		_self.defaults.set(value, forKey: propertyName)
		_self.values[propertyName] = NSNumber(value: value)
	}
	static private let setLongValueIMP: @convention(c) (_Self, Selector, CLong) -> Void = { _self, _cmd, value in
		let propertyName = NSStringFromSelector(_cmd)
		$(propertyName)
		_self.defaults.set(value, forKey: propertyName)
		_self.values[propertyName] = NSNumber(value: value)
	}
	static private let setLongLongValueIMP: @convention(c) (_Self, Selector, CLongLong) -> Void = { _self, _cmd, value in
		let propertyName = NSStringFromSelector(_cmd)
		$(propertyName)
		_self.defaults.set(Int(value), forKey: propertyName)
		_self.values[propertyName] = NSNumber(value: value)
	}

	// MARK: -

	static private let (propertyInfoMap, getterAndSetterMap): ([String : PropertyInfo], [String : PropertyInfo]) = {
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

	static private func isDefaultName(_ name: String) -> Bool {
		return !["values", "defaults"].contains(name)
	}
}

public class KVOCompliantUserDefaults : NSObject {
	var values = [String : NSObject]()
	let defaults = UserDefaults.standard()

	func synchronizeValues() {
		for (propertyName, propertyInfo) in _Self.propertyInfoMap {
			let defaults = self.defaults
			if (_Self.isDefaultName(propertyInfo.name)) {
				let oldValue = values[propertyName]
				let newValue = defaults.object(forKey: propertyName) as! NSObject?
				if (oldValue == newValue) {
				}
				else if (true == (oldValue?.isEqual(newValue))) {
				}
				else {
					self.willChangeValue(forKey: propertyName)
					self.values[propertyName] = newValue
					self.didChangeValue(forKey: propertyName)
				}
			}
		}
	}

	public override static func resolveInstanceMethod(_ sel: Selector) -> Bool {
		let selName = NSStringFromSelector(sel)
		if let propertyInfo = getterAndSetterMap[selName] {
			•(propertyInfo)
			let attributesDictionary = propertyInfo.attributesDictionary;
			let type = attributesDictionary["T"]!
			let isSetter = selName.hasSuffix(":")

			let valueTypeEncoded = String(type.utf8.prefix(1))!
			let methodIMP: IMP = {
				switch (valueTypeEncoded) {
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
				_ = class_addMethod(self, sel, unsafeBitCast(methodIMP, to: OpaquePointer.self), typesCString)
			}
			return true
		}
		return super.resolveInstanceMethod(sel)
	}
	var blocksDelayedTillDealloc = [Handler]()
	deinit {
		blocksDelayedTillDealloc.forEach {$0()}
	}
	
	public override init () {
		super.init()
		let notificationCenter = NotificationCenter.default()
		var handlingNotification = false
		let observer = notificationCenter.addObserver(forName: UserDefaults.didChangeNotification, object:nil, queue:nil) { [unowned self] notification in
			if (!handlingNotification) {
				handlingNotification = true
				self.defaults.synchronize()
				self.synchronizeValues()
				handlingNotification = false
			}
		}
		self.blocksDelayedTillDealloc += [{
			notificationCenter.removeObserver(observer)
		}]
		self.synchronizeValues()
	}
}
