#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "os_activity_shims.h"
#import "os_log_shims.h"
#import "Loggy.h"

FOUNDATION_EXPORT double LoggyVersionNumber;
FOUNDATION_EXPORT const unsigned char LoggyVersionString[];

