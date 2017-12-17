//
//  StatusBarTimeLabel.swift
//  GEUIKit
//
//  Created by Grigorii Entin on 17/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

extension UIApplication {
    
    func statusBarTimeLabelForNonX() -> UIView? {
        
        guard let statusBar = self.value(forKeyPath: "statusBar") as? UIView else {
            return nil
        }
        
        guard let timeLabelClass = NSClassFromString("UIStatusBarTimeItemView") else {
            return nil
        }
        
        let timeLabel = statusBar.view(of: timeLabelClass)
        
        return timeLabel
    }
    
    func statusBarTimeLabelForX() -> UIView? {
        
        guard let statusBar = self.value(forKeyPath: "statusBar") as? UIView else {
            return nil
        }
        
        guard let statusBarStringViewClass = NSClassFromString("_UIStatusBarStringView") else {
            return nil
        }
        
        let timeLabel = statusBar.view(of: statusBarStringViewClass)
        
        return timeLabel
    }
}
