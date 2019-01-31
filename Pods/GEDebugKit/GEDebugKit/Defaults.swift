//
//  Defaults.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 06/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

public extension TypedUserDefaults {
    
    @NSManaged var memoryProfilerEnabled: Bool
    @NSManaged var allocationTrackingEnabled: Bool
    
    @NSManaged var FPSMonitoringEnabled: Bool
}
