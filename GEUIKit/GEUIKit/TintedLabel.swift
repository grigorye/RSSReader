//
//  TintedLabel.swift
//  GEUIKit
//
//  Created by Grigory Entin on 01.12.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

class TintedLabel : UILabel {
	
	// https://stackoverflow.com/a/19262685/1859783
	
	private func forceTintColorAsNecessary() {
	
		textColor = tintColor
	}
	
	override func tintColorDidChange() {
		
		super.tintColorDidChange()
		
		forceTintColorAsNecessary()
	}
	
	required init?(coder aDecoder: NSCoder) {

		super.init(coder: aDecoder)
		
		forceTintColorAsNecessary()
	}
}
