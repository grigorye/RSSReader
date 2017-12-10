//
//  AliveObjectsViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 08/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

let aliveObjectsClassFilter: (AnyClass) -> Bool = {
	
	let parentClassesForAllocationTracking: [AnyClass] = [
		UIResponder.self
	]
	
	return isSubclass($0, forAny: parentClassesForAllocationTracking) || isContainedInUserCode($0)
}

class AliveObjectsViewController : UITableViewController {

	class Data {
		
		var allocationGeneration: AllocationGeneration
		
		lazy var aliveObjects: [String : [WeakRefernece<AnyObject>]] = allocationGeneration.aliveObjects
		
		lazy var aliveObjectsClassNames: [String] = aliveObjects.keys.sorted()
		
		init(generationIndex: Int) {
			
			self.allocationGeneration = AllocationGeneration(generationIndex: generationIndex)
		}
	}
	
	var generationIndex: Int = 0
	
	var dataImp: Data? = nil
	var data: Data {
		return dataImp ?? {
			let data = Data(generationIndex: generationIndex)
			dataImp = data
			return data
		}()
	}
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data.aliveObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "aliveObject", for: indexPath) … {
            
            let className = data.aliveObjectsClassNames[indexPath.row]
            let objects = data.aliveObjects[className]!
            $0.textLabel!.text = "\(className)"
            $0.detailTextLabel!.text = "\(objects.count)"
        }
        return cell
    }
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		setTitleFromData()
	}
	
	func setTitleFromData() {
		
		title = String.localizedStringWithFormat(
			NSLocalizedString("Generation %d (%d objects)", comment: ""),
			self.generationIndex,
			data.allocationGeneration.aliveObjectsCount
		)
	}
	
	func updateForGenerationIndex() {
		
		dataImp = nil
		setTitleFromData()
		tableView.reloadData()
	}
	
	@IBAction func generationForward(_ sender: Any) {
		
		guard generationIndex < lastAllocationGenerationIndex() else {
			return
		}
		
		generationIndex += 1
		updateForGenerationIndex()
	}
	
	@IBAction func generationBackward(_ sender: Any) {
		
		guard 0 < generationIndex else {
			return
		}
		
		generationIndex -= 1
		updateForGenerationIndex()
	}
}
