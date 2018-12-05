//
//  UIFontExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 20.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import UIKit.UIFont

let smallCapsFontFeature: [UIFontDescriptor.FeatureKey : Any] = [
	.featureIdentifier: kLowerCaseType,
	.typeIdentifier: kLowerCaseSmallCapsSelector
]

// Source: http://stackoverflow.com/questions/12941984/typesetting-a-font-in-small-caps-on-ios
extension UIFont {
	
	public func smallCaps() -> UIFont {
		
		let fontAttributes: [UIFontDescriptor.AttributeName : Any] = [
			.featureSettings: [smallCapsFontFeature],
			.name: fontName
		]
		let fontDescriptor = UIFontDescriptor(fontAttributes: fontAttributes)
		let font = UIFont(descriptor: fontDescriptor, size: pointSize)
		return font
	}
}
