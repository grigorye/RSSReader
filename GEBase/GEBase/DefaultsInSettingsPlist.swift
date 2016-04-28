//
//  DefaultsInSettingsPlist.swift
//  GEBase
//
//  Created by Grigory Entin on 28.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public func loadDefaultsFromSettingsPlistAtURL(url: NSURL) throws {
	let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions(rawValue: 0))
    let settingsPlist = try NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListReadOptions(), format: nil) as! NSDictionary
    let preferencesSpecifiers = settingsPlist["PreferenceSpecifiers"] as! [[String : AnyObject]]
	let defaultKeysAndValuesForRegistration: [(key: String, defaultValue: AnyObject)] = preferencesSpecifiers.flatMap {
		guard let key = $0["Key"] as! String? else {
			return nil
		}
		let defaultValue = $0["DefaultValue"]
		return (key: key, defaultValue: defaultValue!)
	}
	let defaultsForRegistration = defaultKeysAndValuesForRegistration.reduce([String : AnyObject]()) {
		var $ = $0
		$[$1.key] = $1.defaultValue
		return $
	}
    NSUserDefaults().registerDefaults($(defaultsForRegistration))
}
