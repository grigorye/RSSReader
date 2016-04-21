//
//  Appearance.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

class ItemCellSmallCapsLabel: UILabel {}
class ItemCellSourceLabel: ItemCellSmallCapsLabel {}
class ItemCellDateLabel: ItemCellSmallCapsLabel {}
class ItemCellFavoriteMarkLabel: ItemCellSmallCapsLabel {}
class ItemCellReadMarkLabel: UILabel {}
class ItemCellTitleLabel: UILabel {}

func configureAppearance() {
	do {
		let label = ItemCellSmallCapsLabel.appearance()
		let styledFont = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
		let font = UIFont.smallCapsFontOfSize(styledFont.pointSize, withName: styledFont.fontName)
		label.font = font
	}
	do {
		let label = ItemCellReadMarkLabel.appearance()
		label.textColor = UIView().tintColor
	}
}
