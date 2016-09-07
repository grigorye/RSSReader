//
//  KVOBinding.swift
//  GEBase
//
//  Created by Grigory Entin on 14.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

private let KVOBindingContext = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 0)

public class KVOBinding : NSObject {
	unowned let object: NSObject
	let keyPath: String
	public typealias KVOHandlerType = ([NSKeyValueChangeKey : Any]?) -> Void
	let KVOHandler: KVOHandlerType
	public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == KVOBindingContext {
			KVOHandler(change)
		}
		else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	public init(_ objectAndKeyPath: ObjectAndKeyPath, options: NSKeyValueObservingOptions, KVOHandler: @escaping KVOHandlerType) {
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
