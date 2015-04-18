//
//  KeyPathRecordingProxy-ReferenceCounting.mm
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KeyPathRecordingProxy-ReferenceCounting.h"

@implementation KeyPathRecordingProxy (ReferenceCounting)

+ (instancetype)alloc;
{
	KeyPathRecordingProxy *instance = super.alloc;
	instance.proxyRetainCount = 1;
	return instance;
}

- (oneway void)release;
{
	self.proxyRetainCount--;
	if (!self.proxyRetainCount) {
		[self dealloc];
	}
}

- (instancetype)retain;
{
	self.proxyRetainCount++;
	return self;
}

@end
