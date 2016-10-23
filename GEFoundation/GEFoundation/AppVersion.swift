//
//  AppVersion.swift
//  GEBase
//
//  Created by Grigory Entin on 11.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GETracing
import Foundation

public let versionIsClean: Bool = {
	let version = Bundle.main.infoDictionary!["CFBundleVersion"] as! NSString
	$(version)
	let buildDate = try! FileManager.default.attributesOfItem(atPath: Bundle.main.bundlePath)[FileAttributeKey.modificationDate] as! Date
	let buildAge = Date().timeIntervalSince(buildDate)
	$(buildAge)
	return NSNotFound == version.rangeOfCharacter(from: NSCharacterSet.decimalDigits.inverted).location
}()
