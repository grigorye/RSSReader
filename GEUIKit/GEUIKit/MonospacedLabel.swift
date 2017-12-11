//
//  MonospacedLabel.swift
//  GEUIKit
//
//  Created by Grigorii Entin on 11/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

public class MonospacedLabel : UILabel {
    
    public required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let nonscaledFont = UIFont(name: "Menlo-Regular", size: UIFont.labelFontSize)!
        let metrics = UIFontMetrics(forTextStyle: UIFontTextStyle.body)
        font = metrics.scaledFont(for: nonscaledFont)
    }
}
