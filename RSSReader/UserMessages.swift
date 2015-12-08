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

func presentErrorMessage(text: String) {
#if true
	AFMInfoBanner.showAndHideWithText(text, style: .Error)
#else
	print("Error: \(text)")
#endif
}
func presentInfoMessage(text: String) {
#if true
	AFMInfoBanner.showAndHideWithText(text, style: .Info)
#else
	print("Info: \(text)")
#endif
}

extension UIViewController {
	func presentErrorMessage(text: String) {
		RSSReader.presentErrorMessage(text)
	}
	func presentInfoMessage(text: String) {
		RSSReader.presentInfoMessage(text)
	}
}
