//
//  NSBundleExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 16/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension Bundle {
	public static func bundle(forStackFrameIndex stackFrameIndex: Int) -> Bundle? {
		precondition(0 <= stackFrameIndex)
		let length = stackFrameIndex + 1
		let addr = UnsafeMutablePointer<UnsafeMutablePointer<Void>?>(allocatingCapacity: length)
		let frames = Int(backtrace(addr, Int32(length)))
		assert(stackFrameIndex < frames)
		var info = Dl_info()
		guard 0 != dladdr(addr[stackFrameIndex], &info) else {
			return nil
		}
		let sharedObjectName = String(validatingUTF8: info.dli_fname)! as NSString
		let bundle = Bundle(path: sharedObjectName.deletingLastPathComponent)!
		addr.deallocateCapacity(length)
		return bundle
	}
}
