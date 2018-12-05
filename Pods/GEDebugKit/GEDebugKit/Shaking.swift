//
//  Shaking.swift
//  GEDebugKit
//
//  Created by Grigory Entin on 11.02.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import func GEUIKit.openSettingsApp
import UIKit

private func debugOnShake() {
	
	openSettingsApp()
}

func configureShakeGesture() {
	
	typealias ImpBlock = @convention(block) (UIWindow?, UIEventSubtype, UIEvent?) -> Void
	typealias Imp = @convention(c) (UIWindow?, Selector, UIEventSubtype, UIEvent?) -> Void
	let sel = #selector(UIWindow.motionEnded(_:with:))
	let method = class_getInstanceMethod(UIWindow.self, sel)!
	let oldImp = unsafeBitCast(method_getImplementation(method), to: Imp.self)
	let impBlock: ImpBlock = { pself, motion, event in
		if event?.subtype == .motionShake {
			debugOnShake()
		}
		return oldImp(pself, sel, motion, event)
	}
	let imp = imp_implementationWithBlock(unsafeBitCast(impBlock, to: AnyObject.self))
	method_setImplementation(method, imp)
}
