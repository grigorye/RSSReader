//
//  ViewOfKind.swift
//  GEUIKit
//
//  Created by Grigorii Entin on 17/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

extension UIView {
    
    func view(of cls: AnyClass) -> UIView? {
        
        guard !self.isKind(of: cls) else {
            return self
        }
        
        for subview in subviews {
            if let viewOfKind = subview.view(of: cls) {
                return viewOfKind
            }
        }
        
        return nil
    }
}
