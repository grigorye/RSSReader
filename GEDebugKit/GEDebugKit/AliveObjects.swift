//
//  AliveObjects.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 09/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import FBAllocationTracker
import Foundation

let allocationTrackerManager = FBAllocationTrackerManager.shared()!

func markAllocationGeneration() {
    
    allocationTrackerManager.markGeneration()
}

struct AllocationGeneration {
	
	let generationIndex: Int
	let classFilter: (AnyClass) -> Bool
	
	init(generationIndex: Int, classFilter: @escaping (AnyClass) -> Bool = aliveObjectsClassFilter) {
		
		self.generationIndex = generationIndex
		self.classFilter = classFilter
	}
	
	lazy var allocationTrackerSummary: [FBAllocationTrackerSummary] = {
		
		let currentSummaryForGenerations = allocationTrackerManager.currentSummaryForGenerations()!
		
		let allocationTrackerSummary = currentSummaryForGenerations[generationIndex]
		
		return allocationTrackerSummary
	}()
	
	lazy var aliveObjectsCount: Int = {
		
		let subclassSummaries = allocationTrackerSummary.filter {
			
			guard let cls = NSClassFromString($0.className) else {
				assert(false)
				return false
			}
			return classFilter(cls)
		}
		
		let clsAndLive = subclassSummaries.map { ($0.className, $0.aliveObjects) }
		x$(clsAndLive)
		
		let aliveObjectsCount = subclassSummaries.reduce(0, {
			let summary = $1
			let aliveObjects = summary.aliveObjects
			//assert(0 < aliveObjects)
			return $0 + aliveObjects
		})
		return aliveObjectsCount
	}()

	lazy var aliveObjects: [String : [WeakRefernece<AnyObject>]] = {
		
		let aliveObjects: [String : [WeakRefernece<AnyObject>]] = allocationTrackerSummary.reduce([:]) {
			
			let className = $1.className
			let cls: AnyClass = NSClassFromString(className)!
			
			guard classFilter(cls) else {
				
				return $0
			}
			guard let objects = allocationTrackerManager.instances(for: cls, inGeneration: generationIndex) as [AnyObject]? else {
				
				return $0
			}
			var reduced = $0
			reduced[className] = objects.map { WeakRefernece(object: $0) }
			
			return reduced
		}
		
		return aliveObjects
	}()
}

func lastAllocationGenerationIndex() -> Int {
	
	let currentSummaryForGenerations = allocationTrackerManager.currentSummaryForGenerations()!
	
	return currentSummaryForGenerations.count - 1
}

func isSubclass(_ cls: AnyClass, forAny parentClasses: [AnyClass]) -> Bool {
    
    for parentClass in parentClasses {
        
        if cls.isSubclass(of: parentClass) {
            
            return true
        }
    }
    
    return false
}

func isContainedInUserCode(_ cls: AnyClass) -> Bool {
    
    return Bundle(for: cls).bundlePath.hasPrefix(Bundle.main.bundlePath)
}
