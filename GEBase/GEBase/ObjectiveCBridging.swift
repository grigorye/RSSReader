//
//  ObjectiveCBridging.swift
//  GEBase
//
//  Created by Grigory Entin on 02.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import Foundation

func objCEncode<T>(type: T.Type) -> String {
	switch type {
	case is Int.Type:
		return String.fromCString((1 as NSNumber).objCType)!
	case is Bool.Type:
		return String.fromCString((true as NSNumber).objCType)!
	case is AnyObject.Type:
		return "@"
	default:
		abort()
	}
}

func objCDefaultSetterNameForPropertyName(propertyName: String) -> String {
	return "set\(propertyName.uppercaseString.characters.first!)\(propertyName.substringFromIndex(propertyName.startIndex.advancedBy(1))):"
}

func objCPropertyAttributeValue(property: objc_property_t, attributeName: String) -> String? {
	let valueCString = property_copyAttributeValue(property, attributeName)
	let $ = String.fromCString(valueCString)
	valueCString.destroy()
	return $;
}

struct PropertyInfo {
	let name: String
	let attributes: String
	let attributesDictionary: [String : String]
}

extension PropertyInfo {
	init(property: objc_property_t) {
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
