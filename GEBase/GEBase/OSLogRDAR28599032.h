//
//  OSLogRDAR28599032.h
//  GEBase
//
//  Created by Grigory Entin on 12.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#import <os/log.h>

@class NSString;

#ifdef __cplusplus
extern "C" {
#endif

void rdar_os_log_with_type(void const *dso, os_log_t log, os_log_type_t type, NSString * message);

#ifdef __cplusplus
}
#endif
