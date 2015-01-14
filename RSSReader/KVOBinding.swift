//
//  KVOBinding.swift
//  RSSReader
//
//  Created by Grigory Entin on 14.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

class KVOBinding : NSObject {
	let context = UnsafeMutablePointer<Void>()
	unowned let object: NSObject
	let keyPath: NSString
	let KVOHandler: (NSDictionary) -> Void
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		if self.context == context {
			KVOHandler(change)
		}
		else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	init(object: NSObject, keyPath: NSString, options: NSKeyValueObservingOptions, KVOHandler: (NSDictionary) -> Void) {
		self.object = object
		self.keyPath = keyPath
		self.KVOHandler = KVOHandler
		super.init()
		object.addObserver(self, forKeyPath: keyPath, options: options, context: context)
	}
	deinit {
		object.removeObserver(self, forKeyPath: keyPath, context: context)
	}
}