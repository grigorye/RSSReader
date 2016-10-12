//
//  OSActivitiesForSwift.h
//  GEBase
//
//  Created by Grigory Entin on 12.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#import <os/activity.h>

#ifdef __cplusplus
extern "C" {
#endif

os_activity_t os_activity_current(void);
os_activity_t os_activity_create_imp(void const *dso, const char *description, os_activity_t activity, os_activity_flag_t);

#define GE_DECL_ACTIVITY_DESCRIPTION(activityName$) \
	extern const char *activityName$ ## ActivityDescription()

#define GE_DEF_ACTIVITY_DESCRIPTION(activityName$, description$) \
const char *activityName$ ## ActivityDescription(void) { \
	OS_LOG_STRING(v, description$); \
	return v; \
}

#ifdef __cplusplus
}
#endif
