//
//  UserMessages.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import SwiftMessages
import UIKit
import Foundation

public func presentErrorMessage(_ text: String, underlyingError error: Error? = nil) {
#if true
	let view = MessageView.viewFromNib(layout: .cardView)…{
		$0.configureTheme(.error)
		$0.configureContent(body: text)
	}
	SwiftMessages.show(view: view)
#else
	print("Error: \(text)")
#endif
}

public func presentInfoMessage(_ text: String) {
#if true
	let view = MessageView.viewFromNib(layout: .cardView)…{
		$0.configureTheme(.info)
		$0.configureContent(body: text)
	}
	SwiftMessages.show(view: view)
#else
	print("Info: \(text)")
#endif
}
