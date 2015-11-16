//
//  NSBundleExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 16/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension NSBundle {
	static func bundleOnStack() -> NSBundle {
		let length = 10
		let addr = UnsafeMutablePointer<UnsafeMutablePointer<Void>>.alloc(length)
		let frames = backtrace(addr, Int32(length))
		assert(2 < frames)
		var info = Dl_info()
		let addrFound = dladdr(addr[2], &info)
		assert(0 != addrFound)
		let sharedObjectName = String.fromCString(info.dli_fname)! as NSString
		let bundle = NSBundle(path: sharedObjectName.stringByDeletingLastPathComponent)!
		return bundle
	}
}
