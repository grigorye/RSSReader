//
//  AliveObjects.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 09/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import FBAllocationTracker
import Foundation

func markAllocationGeneration() {
    
    let allocationTrackerManager = FBAllocationTrackerManager.shared()!
    
    allocationTrackerManager.markGeneration()
}

func aliveObjectsCount(forClassFilter filter: (AnyClass) -> Bool) -> Int {
    
    guard let allocationTrackerManager = FBAllocationTrackerManager.shared() else {
        assert(false)
        return 0
    }
    
    guard let lastGenerationAllocationSummary = allocationTrackerManager.currentSummaryForGenerations()?.last else {
        return 0
    }
    
    let subclassSummaries = lastGenerationAllocationSummary.filter {
        
        guard let cls = NSClassFromString($0.className) else {
            assert(false)
            return false
        }
        return filter(cls)
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
}

func aliveObjects(forClassFilter filter: (AnyClass) -> Bool) -> [String : [WeakRefernece<AnyObject>]] {
    
    let allocationTrackerManager = FBAllocationTrackerManager.shared()!
    
    guard let currentSummaryForGenerations = allocationTrackerManager.currentSummaryForGenerations() else {
        
        return [:]
    }
    
    guard let lastGenerationAllocationSummary = currentSummaryForGenerations.last else {
        
        return [:]
    }
    
    let generationI = currentSummaryForGenerations.count - 1
    
    let aliveObjects: [String : [WeakRefernece<AnyObject>]] = lastGenerationAllocationSummary.reduce([:]) {
        
        let className = $1.className
        let cls: AnyClass = NSClassFromString(className)!
        guard filter(cls) else {
            
            return $0
        }
        guard let objects = allocationTrackerManager.instances(for: cls, inGeneration: generationI) else {
            
            return $0
        }
        var reduced = $0
        reduced[className] = objects.map { WeakRefernece(object: $0 as AnyObject) }
        return reduced
    }
    return aliveObjects
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
