//
//  OpenWebPageActivity.swift
//  RSSReader
//
//  Created by Grigory Entin on 28.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit
import Foundation

class OpenWebPageActivity : UIActivity {
	override func activityType() -> String {
		return "com.grigoryentin.RSSReader.openWebPage"
	}
	override func activityTitle() -> String {
		return NSLocalizedString("Open in Web", comment: "")
	}
	override func activityImage() -> UIImage? {
		return UIImage(named: "AppIcon")
	}
	override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
		let acceptableItems = filter(activityItems) { nil != ($0 as? NSURL) }
		return acceptableItems.count != 0
	}
	var acceptableItems: [NSURL]!
	override func prepareWithActivityItems(activityItems: [AnyObject]) {
		let acceptableItems = activityItems.reduce([NSURL]()) {
			if let x = $1 as? NSURL {
				return $0 + [x]
			}
			else {
				return $0
			}
		}
		self.acceptableItems = acceptableItems
	}
	override func performActivity() {
		let url = acceptableItems.last!
		UIApplication.sharedApplication().openURL(url)
	}
	override class func activityCategory() -> UIActivityCategory {
		return .Action
	}
}
