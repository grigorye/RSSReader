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

private func aliveObjectsForClassFilter(_ filter: (AnyClass) -> Bool) -> Int {
    
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
        return filter(cls)
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

private func isSubclass(_ cls: AnyClass, forAny parentClasses: [AnyClass]) -> Bool {
    
    for parentClass in parentClasses {
        
        if cls.isSubclass(of: parentClass) {
            
            return true
        }
    }
    
    return false
}

private func isContainedInUserCode(_ cls: AnyClass) -> Bool {
    
    return Bundle(for: cls).bundlePath.hasPrefix(Bundle.main.bundlePath)
}

class DebugViewController : AccessibilityAwareStaticTableViewController {
    
    @IBOutlet var memoryProfilerSwitch: UISwitch!
    @IBOutlet var aliveObjectsLabel: UILabel!
    
    @IBAction func toggleMemoryProfiler(_ sender: UISwitch) {
        
        defaults.memoryProfilerEnabled = sender.isOn
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        memoryProfilerSwitch.isOn = defaults.memoryProfilerEnabled

        let parentClassesForAllocationTracking: [AnyClass] = [
            UIResponder.self
        ]
        
        let aliveObjects = aliveObjectsForClassFilter {
            return GEDebugKit.isSubclass($0, forAny: parentClassesForAllocationTracking) || isContainedInUserCode($0)
        }
        
        aliveObjectsLabel?.text = "\(aliveObjects)"
    }
}
