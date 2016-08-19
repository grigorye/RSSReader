//
//  UIFontExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 20.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if os(iOS)

import UIKit.UIFont

// Source: http://stackoverflow.com/questions/12941984/typesetting-a-font-in-small-caps-on-ios
extension UIFont {
	public class func smallCapsFontOfSize(_ size: CGFloat, withName name: String) -> UIFont {
		let fontFeatureSettings = [[
			UIFontFeatureTypeIdentifierKey: kLowerCaseType,
			UIFontFeatureSelectorIdentifierKey: kLowerCaseSmallCapsSelector
		]]
		let fontAttributes: [String : Any] = [
			UIFontDescriptorFeatureSettingsAttribute: fontFeatureSettings,
			UIFontDescriptorNameAttribute: name
		]
		let fontDescriptor = UIFontDescriptor(fontAttributes: fontAttributes)
		let font = UIFont(descriptor: fontDescriptor, size: size)
		return font
	}
}

#endif
