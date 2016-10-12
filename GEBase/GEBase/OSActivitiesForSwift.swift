//
//  OSActivitiesForSwift.swift
//  GEBase
//
//  Created by Grigory Entin on 12.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public func os_activity_create(dso: UnsafeRawPointer = #dsohandle, _ description: UnsafePointer<Int8>!, parent: os_activity_t! = os_activity_current(), flags: os_activity_flag_t = OS_ACTIVITY_FLAG_DEFAULT) -> os_activity_t {
	return os_activity_create_imp(dso, description, parent, flags)
}
