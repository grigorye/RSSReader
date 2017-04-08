//
//  ObjCEncode.swift
//  GEFoundation
//
//  Created by Grigory Entin on 23.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public func objCEncode<T>(_ type: T.Type) -> String {
	switch type {
	case is Int.Type:
		return String(validatingUTF8: (1 as NSNumber).objCType)!
	case is Bool.Type:
		return String(validatingUTF8: (true as NSNumber).objCType)!
	case is AnyObject.Type:
		return "@"
	default:
		abort()
	}
}

public func objCValue(forProperty property: objc_property_t, attributeName: String) -> String? {
	let valueCString = property_copyAttributeValue(property, attributeName)!
	let $ = String(validatingUTF8: valueCString)
	free(valueCString)
	return $;
}
