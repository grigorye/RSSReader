//
//  Debugging.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.12.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import FBAllocationTracker
import FBMemoryProfiler
import FPSCounter
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

private func initializeAllocationTracking() {
    
    var scope = Activity("Initializing Allocation Tracking").enter(); defer { scope.leave() }
    guard let allocationTrackerManager = x$(FBAllocationTrackerManager.shared()) else {
        return
    }
    allocationTrackerManager.startTrackingAllocations()
    allocationTrackerManager.enableGenerations()
}

public func configureAllocationTracking() {
    
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

let fpsMonitor = FPSMonitor()

func configureFPSMonitoring() {
    
    retainedObjects += [
        defaults.observe(\.FPSCounterEnabled, options: .initial) { (_, _) in
            
            if defaults.FPSCounterEnabled {
                fpsMonitor.show()
            } else {
                fpsMonitor.hide()
            }
        }
    ]

}

public func configureDebug() {
    
    configureAllocationTracking()
    configureFPSMonitoring()
}

public func initializeDebug() {
    
    if defaults.allocationTrackingEnabled {
        initializeAllocationTracking()
    }
}
