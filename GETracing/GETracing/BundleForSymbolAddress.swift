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
		let bundleURL: URL = {
			let sharedObjectURL = URL(fileURLWithPath: sharedObjectName)
			if #available(iOS 9, macOS 11, *) {
				return sharedObjectURL.deletingLastPathComponent()
			}
			if #available(macOS 10, *) {
				return sharedObjectURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
			}
			fatalError()
		}()
				
		self.init(url: bundleURL)
	}
}
