//
//  OSLogRDAR28599032.m
//  GEBase
//
//  Created by Grigory Entin on 12.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#import "OSLogRDAR28599032.h"
#import <Foundation/NSString.h>

void rdar_os_log_with_type(void const *dso, os_log_t log, os_log_type_t type, NSString *message) {
#if 1
	_os_log_internal(dso, log, type, "%{public}@", message);
#else
	os_log_fault(log, "%{public}@", message);
#endif
}
