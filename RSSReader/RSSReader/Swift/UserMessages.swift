//
//  UserMessages.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import AFMInfoBanner
import UIKit
import Foundation

func presentErrorMessage(_ text: String) {
#if true
	AFMInfoBanner.showAndHide(withText: text, style: .error)
#else
	print("Error: \(text)")
#endif
}
func presentInfoMessage(_ text: String) {
#if true
	AFMInfoBanner.showAndHide(withText: text, style: .info)
#else
	print("Info: \(text)")
#endif
}

extension UIViewController {
	func presentErrorMessage(_ text: String) {
		RSSReader.presentErrorMessage(text)
	}
	func presentInfoMessage(_ text: String) {
		RSSReader.presentInfoMessage(text)
	}
}
