//
//  UIKitUtilities.swift
//  GEBase
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import UIKit

public func openSettingsApp() {
	let url = URL(string: UIApplication.openSettingsURLString)!
	let application = UIApplication.shared
	if #available(iOS 10.0, *) {
		application.open(url, options: [:], completionHandler: nil)
	} else {
		application.openURL(url)
	}
}
