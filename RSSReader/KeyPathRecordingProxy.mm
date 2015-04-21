//
//  KeyPathRecordingProxy.m
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KeyPathRecordingProxy.h"
#import <objc/runtime.h>

#define let auto const
#define var auto

NSUInteger keyPathRecordingProxyLiveCount;

@implementation KeyPathRecordingProxy

- (BOOL)isKindOfClass:(Class)aClass;
{
	return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [NSObject instanceMethodSignatureForSelector:@selector(description)];
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
	SEL selector = invocation.selector;
	let proxy = self;
	// String bridging
	{
		if (sel_isEqual(selector, @selector(copy))) {
			if (let valueClass = proxy.valueClass) {
				id returnValue = [valueClass new];
				[invocation setReturnValue:&returnValue];
			}
			return;
		}
	}
	// Array bridging
	{
		if (sel_isEqual(selector, @selector(copyWithZone:))) {
			if (let valueClass = proxy.valueClass) {
				id returnValue = [valueClass new];
				[invocation setReturnValue:&returnValue];
			}
			return;
		}
	}
	// Set or Dictionary bridging
	{
		if (sel_isEqual(selector, @selector(count))) {
			NSUInteger returnValue = 0;
			[invocation setReturnValue:&returnValue];
			return;
		}
	}
	// Set bridging
	{
		if (sel_isEqual(selector, @selector(getObjects:))) {
			return;
		}
		if (sel_isEqual(selector, @selector(enumerateObjectsUsingBlock:))) {
			return;
		}
	}
	// Dictionary bridging
	{
		if (sel_isEqual(selector, @selector(enumerateKeysAndObjectsUsingBlock:))) {
			return;
		}
	}
	{
		proxy.keyPathComponents = ^{
			let lastKeyPathComponents = @[NSStringFromSelector(invocation.selector)];
			if (let oldKeyPathComponents = proxy.keyPathComponents) {
				return [oldKeyPathComponents arrayByAddingObjectsFromArray:lastKeyPathComponents];
			}
			else {
				return lastKeyPathComponents;
			}
		}();
		if (0 == strcmp(invocation.methodSignature.methodReturnType, @encode(id))) {
			id returnValue = self;
			[invocation setReturnValue:&returnValue];
		}
	}
}

#pragma mark -

#if 1
- (void)dealloc;
{
	--keyPathRecordingProxyLiveCount;
}

+ (id)alloc;
{
	let proxy = [super alloc];
	++keyPathRecordingProxyLiveCount;
	return proxy;
}
#endif

@end
