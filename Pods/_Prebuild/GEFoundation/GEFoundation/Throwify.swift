//
//  Throwify.swift
//  GEFoundation
//
//  Created by Grigory Entin on 14/08/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

private enum ThrowifyError : Error {
	case falseValue
	case nilValue
}

public func throwify(_ block: @autoclosure () -> Bool) throws {
	if !block() {
		throw ThrowifyError.falseValue
	}
}

public func throwify<T>(_ block: @autoclosure () -> T?) throws -> T {
	guard let value = block() else {
		throw ThrowifyError.nilValue
	}
	return value
}
