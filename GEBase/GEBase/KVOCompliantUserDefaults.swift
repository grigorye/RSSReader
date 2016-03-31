//
//  KVOCompliantUserDefaults.swift
//  GEBase
//
//  Created by Grigory Entin on 15/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

private let objcEncode_Bool = String.fromCString(NSNumber(bool: true).objCType)!
private let objcEncode_C99Bool = "B"
private let objcEncode_AnyObject = "@"

private struct PropertyInfo {
	let name: String
	let attributes: String
	let attributesDictionary: [String : String]
}

extension PropertyInfo {
	init (property: objc_property_t) {
		self.name = String.fromCString(property_getName(property))!
		self.attributes = String.fromCString(property_getAttributes(property))!
		self.attributesDictionary = {
			var attributesCount = UInt32(0)
			let attributesList = property_copyAttributeList(property, &attributesCount)
			var $ = [String : String]()
			for i in 0..<Int(attributesCount) {
				let attribute = attributesList[i]
				let attributeName = String.fromCString(attribute.name)!
				let attributeValue = String.fromCString(attribute.value)!
				$[attributeName] = attributeValue
			}
			free(attributesList)
			return $
		}()
	}
}

// MARK: -

extension KVOCompliantUserDefaults {
	typealias _Self = KVOCompliantUserDefaults

	static private func defaultNameForSelector(sel: Selector) -> String {
		let selName = NSStringFromSelector(sel)
		let propertyInfo = getterAndSetterMap[selName]!
		(propertyInfo)
		let defaultName = propertyInfo.name
		return defaultName
	}
	static private let objectValueIMP: @convention(c) (_Self, Selector) -> AnyObject? = { _self, _cmd in
		let propertyName = NSStringFromSelector(_cmd)
		let value = _self.values[propertyName]
		(propertyName)
		return (value)
	}
	static private let setObjectValueIMP: @convention(c) (_Self, Selector, NSObject?) -> Void = { _self, _cmd, value in
		let defaultName = _Self.defaultNameForSelector(_cmd)
		_self.defaults.setObject(value, forKey:(defaultName))
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
		(propertyName)
		return (value)
	}

	static private let setBoolValueIMP: @convention(c) (_Self, Selector, Bool) -> Void = { _self, _cmd, value in
		let propertyName = NSStringFromSelector(_cmd)
		$(propertyName)
		_self.defaults.setBool(value, forKey: propertyName)
		_self.values[propertyName] = NSNumber(bool: value)
	}

	// MARK: -

	static private let (propertyInfoMap, getterAndSetterMap): ([String : PropertyInfo], [String : PropertyInfo]) = {
		var propertyInfoMap = [String : PropertyInfo]()
		var getterAndSetterMap = [String : PropertyInfo]()
		var propertyCount = UInt32(0)
		let propertyList = class_copyPropertyList(KVOCompliantUserDefaults.self, &propertyCount)
		for i in 0..<Int(propertyCount) {
			let property = propertyList[i]
			let propertyInfo = PropertyInfo(property: property)
			let attributesDictionary = propertyInfo.attributesDictionary
			let propertyName = propertyInfo.name
			let customSetterName = attributesDictionary["S"]
			let customGetterName = attributesDictionary["G"]
			let defaultGetterName = propertyName
			let defaultSetterName = "set\(propertyName.uppercaseString.characters.first!)\(propertyName.substringFromIndex(propertyName.startIndex.advancedBy(1))):"
			getterAndSetterMap[customGetterName ?? defaultGetterName] = propertyInfo
			getterAndSetterMap[customSetterName ?? defaultSetterName] = propertyInfo
			propertyInfoMap[propertyName] = propertyInfo
		}
		free(propertyList)
		return (propertyInfoMap, getterAndSetterMap)
	}()

	static private func isDefaultName(name: String) -> Bool {
		return !["values", "defaults"].containsObject(name)
	}
}

public class KVOCompliantUserDefaults : NSObject {
	var values = [String : NSObject]()
	let defaults = NSUserDefaults.standardUserDefaults()

	func synchronizeValues() {
		for (propertyName, propertyInfo) in _Self.propertyInfoMap {
			let defaults = self.defaults
			if (_Self.isDefaultName(propertyInfo.name)) {
				let oldValue = values[propertyName]
				let newValue = defaults.objectForKey(propertyName) as! NSObject?
				if (oldValue == newValue) {
				}
				else if (true == (oldValue?.isEqual(newValue))) {
				}
				else {
					self.willChangeValueForKey(propertyName)
					self.values[propertyName] = newValue
					self.didChangeValueForKey(propertyName)
				}
			}
		}
	}

	public override static func resolveInstanceMethod(sel: Selector) -> Bool {
		let selName = NSStringFromSelector(sel)
		if let propertyInfo = getterAndSetterMap[selName] {
			(propertyInfo)
			let attributesDictionary = propertyInfo.attributesDictionary;
			let type = attributesDictionary["T"]!
			let isSetter = selName.hasSuffix(":")
			let valueTypeEncoded = type.substringToIndex(type.startIndex.advancedBy(1))
			let methodIMP: IMP = {
				switch (valueTypeEncoded) {
				case objcEncode_Bool, objcEncode_C99Bool:
					return isSetter ? unsafeBitCast(setBoolValueIMP, IMP.self) : unsafeBitCast(boolValueIMP, IMP.self)
				case objcEncode_AnyObject:
					return isSetter ? unsafeBitCast(setObjectValueIMP, IMP.self) : unsafeBitCast(objectValueIMP, IMP.self)
				default:
					fatalError("\(L(valueTypeEncoded))")
				}
			}()
			let types = isSetter ? "v@:\(valueTypeEncoded)" : "\(valueTypeEncoded)@:"
			types.withCString { typesCString in
				class_addMethod(self, sel, unsafeBitCast(methodIMP, COpaquePointer.self), typesCString)
			}
			return true
		}
		return super.resolveInstanceMethod(sel)
	}

	var blocksDelayedTillDealloc = [Handler]()
	deinit {
		for i in blocksDelayedTillDealloc { i() }
	}
	
	public override init () {
		super.init()
		let notificationCenter = NSNotificationCenter.defaultCenter()
		var handlingNotification = false
		let observer = notificationCenter.addObserverForName(NSUserDefaultsDidChangeNotification, object:nil, queue:nil) { [unowned self] notification in
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
