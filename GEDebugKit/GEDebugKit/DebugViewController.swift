//
//  DebugViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 05/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEUIKit

/// Abusing segues to support debug actions.
extension UIViewController {
    
    func postprocessUnwindSegueFromDebugViewController(_ segue: UIStoryboardSegue) {
        
        let debugViewController = segue.source as! DebugViewController
        let tableView = debugViewController.tableView!
        let indexPathToLastSelectedRow = tableView.indexPathsForSelectedRows!.last!
        
        tableView.deselectRow(at: indexPathToLastSelectedRow, animated: true)
    }
    
    @IBAction func unwindToForceDebugCrash(_ segue: UIStoryboardSegue) {
        
        defer { postprocessUnwindSegueFromDebugViewController(segue) }
        
        forceDebugCrash()
    }
    
    @IBAction func unwindToTriggerDebugError(_ segue: UIStoryboardSegue) {
        
        defer { postprocessUnwindSegueFromDebugViewController(segue) }
        
        triggerDebugError()
    }
    
    @IBAction func unwindToToggleMemoryProfiler(_ segue: UIStoryboardSegue) {
        
        defer { postprocessUnwindSegueFromDebugViewController(segue) }
        
        defaults.memoryProfilerEnabled = !defaults.memoryProfilerEnabled
    }
    
    @IBAction func unwindToMarkAllocationGeneration(_ segue: UIStoryboardSegue) {
        
        defer { postprocessUnwindSegueFromDebugViewController(segue) }
        
        markAllocationGeneration()
    }
}

class DebugViewController : AccessibilityAwareStaticTableViewController {
    
    @IBOutlet var memoryProfilerSwitch: UISwitch!
    @IBOutlet var aliveObjectsLabel: UILabel!
    
    var shouldMarkGeneration = false
    
    @IBAction func toggleMemoryProfiler(_ sender: UISwitch) {
        
        defaults.memoryProfilerEnabled = sender.isOn
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        if shouldMarkGeneration {
            
            shouldMarkGeneration = false
            markAllocationGeneration()
        }
    }
    
    let classFilter: (AnyClass) -> Bool = {
        
        let parentClassesForAllocationTracking: [AnyClass] = [
            UIResponder.self
        ]
        
        return GEDebugKit.isSubclass($0, forAny: parentClassesForAllocationTracking) || isContainedInUserCode($0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        memoryProfilerSwitch.isOn = defaults.memoryProfilerEnabled
        
        let aliveObjectsCount = GEDebugKit.aliveObjectsCount(forClassFilter: classFilter)
        
        aliveObjectsLabel?.text = "\(aliveObjectsCount)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case "showAliveObjects"?:
            
            segue.destination as! AliveObjectsViewController … {
                
                $0.aliveObjects = aliveObjects(forClassFilter: classFilter)
            }
            
        default: ()
        }
    }
}

