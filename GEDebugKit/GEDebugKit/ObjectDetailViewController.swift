//
//  ObjectDetailsViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 11/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEUIKit
import Foundation

class ObjectDetailViewController : AccessibilityAwareStaticTableViewController {
    
    struct Data {
        let object: AnyObject
    }
    
    var data = Data(object: NSNull()) {
        didSet {
            if nil != viewIfLoaded {
                updateViewForData()
            }
        }
    }
    
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var classNameLabel: UILabel!
    @IBOutlet var otherInstancesLabel: UILabel!
    
    func updateViewForData() {
        
        let object = data.object
        let pointer = Unmanaged.passUnretained(object).toOpaque()
        addressLabel.text = "\(pointer)"
        classNameLabel.text = "\(type(of: object))"
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateViewForData()
    }
}
