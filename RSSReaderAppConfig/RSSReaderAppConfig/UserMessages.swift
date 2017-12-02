//
//  UserMessages.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import JGProgressHUD
import UIKit
import Foundation

public func presentErrorMessage(_ text: String, underlyingError error: Error? = nil) {
#if true
	let hud = JGProgressHUD(style: .light) … {
		$0.textLabel.text = text
		$0.indicatorView = JGProgressHUDErrorIndicatorView()
		$0.interactionType = .blockTouchesOnHUDView
	}
	hud.show(in: UIApplication.shared.keyWindow!)
	hud.dismiss(afterDelay: 1.0)
#else
	print("Error: \(text)")
#endif
}

public func presentInfoMessage(_ text: String) {
#if true
	let hud = JGProgressHUD(style: .light) … {
		$0.textLabel.text = text
		$0.indicatorView = JGProgressHUDSuccessIndicatorView()
		$0.interactionType = .blockTouchesOnHUDView
	}
	hud.show(in: UIApplication.shared.keyWindow!)
	hud.dismiss(afterDelay: 3.0)
#else
	print("Info: \(text)")
#endif
}
