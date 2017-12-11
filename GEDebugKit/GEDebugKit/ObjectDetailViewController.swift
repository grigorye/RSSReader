//
//  AliveObjectDetailsViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 11/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEUIKit
import Foundation

class ObjectDetailViewController : AccessibilityAwareStaticTableViewController {
    
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var classNameLabel: UILabel!
    @IBOutlet var otherInstancesLabel: UILabel!
    
    func configure(from object: AnyObject) {
        
        var unsafeObject = object
        withUnsafePointer(to: &unsafeObject) {
            addressLabel.text = "\($0)"
        }
        classNameLabel.text = "\(type(of: object))"
    }
}
