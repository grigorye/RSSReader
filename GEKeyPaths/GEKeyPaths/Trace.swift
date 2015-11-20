//
//  Trace.swift
//  GEKeyPaths
//
//  Created by Grigory Entin on 20/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

struct Traceable<T> {
	let x: T
	func $(level: Int) -> T {
		return x
	}
}
func $<T>(x: T) -> Traceable<T> {
	return Traceable(x: x)
}
