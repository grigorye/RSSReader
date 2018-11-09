//
//  Sugar.swift
//  GETracing
//
//  Created by Grigory Entin on 09/11/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

func nnil<T>(_ v: T?, file: StaticString = #file, line: UInt = #line) -> T? {
	guard let v = v else {
		dump(Thread.callStackSymbols, name: "callStackSymbols")
		dump(Thread.callStackReturnAddresses.map {$0.uintValue}, name: "callStackReturnAddresses")
		assertionFailure("Unexpected nil", file: file, line: line)
		return nil
	}
	return v
}
