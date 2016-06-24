//
//  AssociatedObjects.swift
//  GEBase
//
//  Created by Grigory Entin on 03.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

func associatedObjectRegeneratedAsNecessary<T>(obj: AnyObject!, key: UnsafePointer<Void>, type: T.Type) -> T {
	void(NSValue(pointer: unsafeAddress(of: (obj))))
	guard let existingObject = objc_getAssociatedObject(obj, key) as! T! else {
		let newObject = (type as! NSObject.Type).init()
		objc_setAssociatedObject(obj, key, newObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return newObject as! T
	}
	return existingObject
}

func associatedObjectRegeneratedAsNecessary<T>(cls obj: AnyClass!, key: UnsafePointer<Void>, type: T.Type) -> T {
	void(NSValue(pointer: unsafeAddress(of: (obj))))
	guard let existingObject = objc_getAssociatedObject(obj, key) as! T! else {
		let newObject = (type as! NSObject.Type).init()
		objc_setAssociatedObject(obj, key, newObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return newObject as! T
	}
	return existingObject
}
