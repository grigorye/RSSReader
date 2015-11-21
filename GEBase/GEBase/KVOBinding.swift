//
//  KVOBinding.swift
//  GEBase
//
//  Created by Grigory Entin on 14.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEKeyPaths
import Foundation

private let KVOBindingContext = UnsafeMutablePointer<Void>.alloc(1)

public class KVOBinding : NSObject {
	unowned let object: NSObject
	let keyPath: String
	let KVOHandler: (NSDictionary?) -> Void
	override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if context == KVOBindingContext {
			KVOHandler(change)
		}
		else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	public init(_ objectAndKeyPath: ObjectAndKeyPath, options: NSKeyValueObservingOptions, KVOHandler: (NSDictionary?) -> Void) {
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