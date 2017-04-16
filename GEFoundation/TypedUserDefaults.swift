//
//  TypedUserDefaults.swift
//  GEBase
//
//  Created by Grigory Entin on 15/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import UIKit
import Foundation

public let defaults = TypedUserDefaults()!

private let objcEncode_Bool = String(validatingUTF8: NSNumber(value: true).objCType)!
private let objcEncode_Int = "i"
private let objcEncode_Long = "l"
private let objcEncode_LongLong = "q"
private let objcEncode_C99Bool = "B"
private let objcEncode_AnyObject = "@"

// MARK: -

typealias _Self = TypedUserDefaults

private let objectValueIMP: @convention(c) (_Self, Selector) -> AnyObject? = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let value = _self.defaults.object(forKey: propertyName) as AnyObject?
	•(propertyName)
	return (value)
}
private let setObjectValueIMP: @convention(c) (_Self, Selector, NSObject?) -> Void = { _self, _cmd, value in
	let defaultName = _Self.defaultNameForSelector(_cmd)
	_self.defaults.set(value, forKey:(defaultName))
}
private let boolValueIMP: @convention(c) (_Self, Selector) -> Bool = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let value = _self.defaults.bool(forKey: propertyName)
	•(propertyName)
	return (value)
}
private let longValueIMP: @convention(c) (_Self, Selector) -> CLong = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let value = _self.defaults.integer(forKey: propertyName)
	•(propertyName)
	return (value)
}
private let longLongValueIMP: @convention(c) (_Self, Selector) -> CLongLong = { _self, _cmd in
	let propertyName = NSStringFromSelector(_cmd)
	let value = _self.defaults.integer(forKey: propertyName)
	•(propertyName)
	return CLongLong(value)
}

private let setBoolValueIMP: @convention(c) (_Self, Selector, Bool) -> Void = { _self, _cmd, value in
	let propertyName = NSStringFromSelector(_cmd)
	$(propertyName)
	_self.defaults.set(value, forKey: propertyName)
}
private let setLongValueIMP: @convention(c) (_Self, Selector, CLong) -> Void = { _self, _cmd, value in
	let propertyName = NSStringFromSelector(_cmd)
	$(propertyName)
	_self.defaults.set(value, forKey: propertyName)
}
private let setLongLongValueIMP: @convention(c) (_Self, Selector, CLongLong) -> Void = { _self, _cmd, value in
	let propertyName = NSStringFromSelector(_cmd)
	$(propertyName)
	_self.defaults.set(Int(value), forKey: propertyName)
}

extension TypedUserDefaults {
	typealias _Self = TypedUserDefaults

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
		let propertyList = class_copyPropertyList(_Self.self, &propertyCount)!
		for i in 0..<Int(propertyCount) {
			let property = propertyList[i]!
			let propertyInfo = PropertyInfo(property: property)
			let attributesDictionary = propertyInfo.attributesDictionary
			let propertyName = propertyInfo.name
			guard isDefaultName(propertyName) else {
				continue
			}
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
		return ![#keyPath(defaults)].contains(name)
	}
}

public class TypedUserDefaults : NSObject {

	var defaults: UserDefaults
	
	override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
		var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
		guard nil != getterAndSetterMap[key] else {
			return keyPaths
		}
		keyPaths.insert(#keyPath(defaults) + "." + key)
		return keyPaths
	}
	
	public override static func resolveInstanceMethod(_ sel: Selector) -> Bool {
		guard !super.resolveClassMethod(sel) else {
			return true
		}
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
	
	public init?(suiteName: String? = nil) {
		guard let defaults = UserDefaults(suiteName: suiteName) else {
			return nil
		}
		self.defaults = defaults
		super.init()
	}
	
	override public convenience init() {
		self.init(suiteName: nil)!
	}
}
