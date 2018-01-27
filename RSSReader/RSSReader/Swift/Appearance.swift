//
//  Appearance.swift
//  RSSReader
//
//  Created by Grigory Entin on 20.04.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import UIKit

class ItemCellSourceLabel: ItemCellSmallCapsLabel {}
class ItemCellDateLabel: ItemCellSmallCapsLabel {}
class ItemCellFavoriteMarkLabel: ItemCellSmallCapsLabel {}
class ItemCellReadMarkLabel: UILabel {}
class ItemCellReadMarkBar: UIView {}
class ItemCellTitleLabel: UILabel {}

class FolderTableView : UITableView {}

/// - Tag: Appearance-Configuration

class ItemCellSmallCapsLabel : UILabel {
	
	#if true
	required init?(coder aDecoder: NSCoder) {
		
		super.init(coder: aDecoder)
		
		let font = UIFont.preferredFont(forTextStyle: .footnote).smallCaps()
		self.font = font
	}
	#endif
}

func configureAppearance() {
	#if false
		do {
			let label = ItemCellSmallCapsLabel.appearance()
			let font = UIFont.preferredFont(forTextStyle: .footnote).smallCaps()
			label.font = font
		}
	#endif
	do {
		let label = ItemCellReadMarkLabel.appearance()
		label.textColor = UIView().tintColor
	}
	do {
		let bar = ItemCellReadMarkBar.appearance()
		bar.backgroundColor = UIView().tintColor
	}
	do {
		ItemTableView.appearance() … {
			$0.separatorStyle = .none
		}
	}
	do {
		FolderTableView.appearance() … {
			$0.separatorStyle = .none
		}
	}
}
