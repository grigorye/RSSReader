//
//  NSBundleExtensions.mm
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "NSBundleExtensions.h"
#import <execinfo.h>
#import <dlfcn.h>

#define let auto const
#define var auto

@implementation NSBundle (Backtrace)

+ (NSBundle *)bundleOnStack;
{
	void *addr[10];
    let frames = backtrace(&addr[0], sizeof(addr) / sizeof(addr[0]));
	assert(2 < frames);
	Dl_info info;
	let addrFound = dladdr(addr[2], &info);
	assert(addrFound);
	let sharedObjectName = [NSString stringWithUTF8String:info.dli_fname];
	let bundle = [NSBundle bundleWithPath:sharedObjectName.stringByDeletingLastPathComponent];
	return bundle;
}

@end
