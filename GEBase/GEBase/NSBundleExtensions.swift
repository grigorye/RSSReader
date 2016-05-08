//
//  NSBundleExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 16/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension NSBundle {
	public static func bundleOnStackFrame(stackFrameIndex: Int) -> NSBundle? {
		precondition(0 <= stackFrameIndex)
		let length = stackFrameIndex + 1
		let addr = UnsafeMutablePointer<UnsafeMutablePointer<Void>>.alloc(length)
		let frames = Int(backtrace(addr, Int32(length)))
		assert(stackFrameIndex < frames)
		var info = Dl_info()
		guard 0 != dladdr(addr[stackFrameIndex], &info) else {
			return nil
		}
		let sharedObjectName = String.fromCString(info.dli_fname)! as NSString
		let bundle = NSBundle(path: sharedObjectName.stringByDeletingLastPathComponent)!
		addr.dealloc(length)
		return bundle
	}
}
