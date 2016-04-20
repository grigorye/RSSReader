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
class ItemCellReadMarkLabel: ItemCellSmallCapsLabel {}
class ItemCellTitleLabel: UILabel {}

func configureAppearance() {
	let styledFont = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
	let font = UIFont.smallCapsFontOfSize(styledFont.pointSize, withName: styledFont.fontName)
	let label = ItemCellSmallCapsLabel.appearance()
	label.font = font
}
