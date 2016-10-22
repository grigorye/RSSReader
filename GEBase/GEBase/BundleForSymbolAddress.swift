//
//  BundleForSymbolAddress.swift
//  GEBase
//
//  Created by Grigory Entin on 16/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension Bundle {
	public convenience init?(for symbolAddr: UnsafeRawPointer) {
		var info = Dl_info()
		guard 0 != dladdr(symbolAddr, &info) else {
			return nil
		}
		let sharedObjectName = String(validatingUTF8: info.dli_fname)!
		let bundleURL = URL(fileURLWithPath: sharedObjectName).deletingLastPathComponent()
		self.init(url: bundleURL)
	}
}
