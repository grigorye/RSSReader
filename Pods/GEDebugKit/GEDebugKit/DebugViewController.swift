//
//  DebugViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 05/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import GEUIKit
import UIKit

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
	@IBOutlet var aliveObjectsCell: UITableViewCell!
	
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
	
	lazy var allocationGeneration = AllocationGeneration(generationIndex: lastAllocationGenerationIndex())
	
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        memoryProfilerSwitch.isOn = defaults.memoryProfilerEnabled
		
		let liveObjectsText: String = {
			guard allocationTrackingEnabled else {
				return NSLocalizedString("Not Available", comment: "")
			}
			let aliveObjectsCount = allocationGeneration.aliveObjectsCount
			return "\(aliveObjectsCount)"
		}()

        aliveObjectsLabel?.text = liveObjectsText
		aliveObjectsCell.selectionStyle = allocationTrackingEnabled ? .default : .none
		aliveObjectsCell.accessoryType = allocationTrackingEnabled ? .disclosureIndicator : .none
    }
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
	
		if identifier == "showAliveObjects" && !allocationTrackingEnabled {
			return false
		}
		
		return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
	}
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case "showAliveObjects"?:
            
            segue.destination as! GenerationViewController … {
                
                $0.generationIndex = allocationGeneration.generationIndex
            }
            
        default: ()
        }
    }
}
