//
//  Debugging.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.12.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEFoundation
import Foundation

private let debugError = NSError(domain: "com.grigorye.debug", code: 1)

public func forceDebugCrash() {
	
	fatalError()
}

public func triggerDebugError() {
	
	trackError(debugError)
}
