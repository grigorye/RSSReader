//
//  ObjectiveCBridging.swift
//  GEBase
//
//  Created by Grigory Entin on 02.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import Foundation

class ObjCSampleObject : NSObject {
	@objc dynamic var intProperty: Int {
		return 0
	}
	@objc dynamic var boolProperty: Bool {
		return true
	}
	@objc dynamic var objectProperty: NSObject! {
		return 0
	}
	@objc dynamic var anyObjectProperty: AnyObject! {
		return 0
	}
}

public func objCGetterMethodEncoding<T>(type: T.Type) -> String {
	let samplePropertyName: String = {
		switch (type) {
		case is Bool.Type:
			return ObjCSampleObject.self••{$0.boolProperty}
		case is Int.Type:
			return ObjCSampleObject.self••{$0.intProperty}
		case is AnyObject.Type:
			return ObjCSampleObject.self••{$0.anyObjectProperty}
		case is NSObject.Type:
			return ObjCSampleObject.self••{$0.objectProperty}
		default:
			abort()
		}
	}()
	return String.fromCString(method_getTypeEncoding(class_getInstanceMethod(ObjCSampleObject.self, NSSelectorFromString(samplePropertyName))))!
}
