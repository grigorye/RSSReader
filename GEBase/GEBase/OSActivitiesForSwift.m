//
//  OSActivitiesForSwift.m
//  GEBase
//
//  Created by Grigory Entin on 12.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#import "OSActivitiesForSwift.h"

os_activity_t os_activity_create_imp(void const *dso, const char *description, os_activity_t activity, os_activity_flag_t flags) {
	return _os_activity_create(dso, description, activity, flags);
}

os_activity_t os_activity_current(void) {
	return OS_ACTIVITY_CURRENT;
}
