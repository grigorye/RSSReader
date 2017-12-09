//
//  Debugging.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.12.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import FBAllocationTracker
import FBMemoryProfiler
import Loggy
import Foundation

private let debugError = NSError(domain: "com.grigorye.debug", code: 1)

public func forceDebugCrash() {
	
	fatalError()
}

public func triggerDebugError() {
	
	trackError(debugError)
}

private var retainedObjects: [AnyObject] = []

public func initializeAllocationTracking() {
    var scope = Activity("Initializing Allocation Tracking").enter(); defer { scope.leave() }
    guard let allocationTrackerManager = x$(FBAllocationTrackerManager.shared()) else {
        return
    }
    allocationTrackerManager.startTrackingAllocations()
    allocationTrackerManager.enableGenerations()
}

public func configureDebug() {
    
    if _0 {
        if defaults.memoryProfilerEnabled {
            let memoryProfiler = FBMemoryProfiler()
            memoryProfiler.enable()
            retainedObjects += [memoryProfiler]
        }
    }
    else {
        var memoryProfiler: FBMemoryProfiler!
        retainedObjects += [
            defaults.observe(\.memoryProfilerEnabled, options: .initial) { (_, _) in
                if defaults.memoryProfilerEnabled {
                    guard nil == memoryProfiler else {
                        return
                    }
                    memoryProfiler = FBMemoryProfiler()
                    memoryProfiler.enable()
                }
                else {
                    guard nil != memoryProfiler else {
                        return
                    }
                    memoryProfiler.disable()
                    memoryProfiler = nil
                }
            }
        ]
    }
}

public func initializeDebug() {
    
    if defaults.allocationTrackingEnabled {
        initializeAllocationTracking()
    }
}
