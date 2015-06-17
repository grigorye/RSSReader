//
//  KVOBinding.swift
//  RSSReader
//
//  Created by Grigory Entin on 14.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

private let KVOBindingContext = UnsafeMutablePointer<Void>.alloc(1)

class KVOBinding : NSObject {
	unowned let object: NSObject
	let keyPath: String
	let KVOHandler: (NSDictionary?) -> Void
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if context == KVOBindingContext {
			KVOHandler(change)
		}
		else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	init(_ objectAndKeyPath: ObjectAndKeyPath, options: NSKeyValueObservingOptions, KVOHandler: (NSDictionary?) -> Void) {
		self.object = objectAndKeyPath.object
		self.keyPath = objectAndKeyPath.keyPath
		self.KVOHandler = KVOHandler
		super.init()
		object.addObserver(self, forKeyPath: keyPath, options: options, context: KVOBindingContext)
	}
	deinit {
		object.removeObserver(self, forKeyPath: keyPath, context: KVOBindingContext)
	}
}