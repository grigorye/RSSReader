//
//  UserMessages.swift
//  RSSReader
//
//  Created by Grigory Entin on 12.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

func presentErrorMessage(text: String) {
	AFMInfoBanner.showAndHideWithText(text, style: .Error)
}
func presentInfoMessage(text: String) {
	AFMInfoBanner.showAndHideWithText(text, style: .Info)
}

extension UIViewController {
	func presentErrorMessage(text: String) {
		RSSReader.presentErrorMessage(text)
	}
	func presentInfoMessage(text: String) {
		RSSReader.presentInfoMessage(text)
	}
}
