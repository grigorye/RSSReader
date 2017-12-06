//
//  DebugViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 05/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEUIKit
import GETracing
import FBAllocationTracker

private func aliveObjectsForSubclasses(of parentClasses: [AnyClass]) -> Int {
    
    guard let allocationTrackerManager = FBAllocationTrackerManager.shared() else {
        assert(false)
        return 0
    }
    
    guard let allocationSummaries = allocationTrackerManager.currentAllocationSummary() else {
        assert(false)
        return 0
    }
    
    let subclassSummaries = allocationSummaries.filter {
        
        guard let cls = NSClassFromString($0.className) else {
            assert(false)
            return false
        }
        for parentClass in parentClasses {
            if cls.isSubclass(of: parentClass) {
                return true
            }
        }
        return false
    }
    
    let clsAndLive = subclassSummaries.map { ($0.className, $0.aliveObjects) }
    x$(clsAndLive)
    
    let aliveObjects = subclassSummaries.reduce(0, {
        let summary = $1
        let aliveObjects = summary.aliveObjects
        //assert(0 < aliveObjects)
        return $0 + aliveObjects
    })
    return aliveObjects
}

class DebugViewController : AccessibilityAwareStaticTableViewController {
    
    @IBOutlet var aliveObjectsLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let parentClassesForAllocationTracking: [AnyClass] = [
            UIResponder.self
        ]
        
        let aliveObjects = aliveObjectsForSubclasses(of: parentClassesForAllocationTracking)
        aliveObjectsLabel?.text = "\(aliveObjects)"
    }
}
