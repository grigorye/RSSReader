//
//  KeyPathRecordingProxy.m
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KeyPathRecordingProxy.h"
#import <Foundation/NSSet.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSMethodSignature.h>
#import <objc/runtime.h>
#import <assert.h>
#import <string.h>

#define let auto const
#define var auto

NSUInteger keyPathRecordingProxyLiveCount;

@implementation KeyPathRecordingProxy

+ (instancetype)newProxy;
{
	return [KeyPathRecordingProxy alloc];
}

- (BOOL)isKindOfClass:(Class)aClass;
{
	return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
	if (sel_isEqual(sel, @selector(count))) {
		return [NSSet instanceMethodSignatureForSelector:sel];
	}
	else if (sel_isEqual(sel, @selector(copyWithZone:))) {
		return [NSArray instanceMethodSignatureForSelector:sel];
	}
	else if (sel_isEqual(sel, @selector(enumerateObjectsUsingBlock:))) {
		return [NSSet instanceMethodSignatureForSelector:sel];
	}
	else if (sel_isEqual(sel, @selector(enumerateKeysAndObjectsUsingBlock:))) {
		return [NSDictionary instanceMethodSignatureForSelector:sel];
	}
	else if (sel_isEqual(sel, @selector(getObjects:))) {
		return [NSArray instanceMethodSignatureForSelector:sel];
	}
	else {
		assert(![NSStringFromSelector(sel) hasSuffix:@":"]);
		return [NSObject instanceMethodSignatureForSelector:@selector(description)];
	}
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
	let selector = invocation.selector;
	// String bridging
	{
		if (sel_isEqual(selector, @selector(copy))) {
			id returnValue = @"";
			[invocation setReturnValue:&returnValue];
			return;
		}
	}
	// Array bridging
	{
		if (sel_isEqual(selector, @selector(copyWithZone:))) {
			id returnValue = @[];
			[invocation setReturnValue:&returnValue];
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
		if (sel_isEqual(selector, @selector(enumerateObjectsUsingBlock:))) {
			return;
		}
		if (sel_isEqual(selector, @selector(getObjects:))) {
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
		self.keyPathComponents = [[NSArray arrayWithArray:self.keyPathComponents] arrayByAddingObjectsFromArray:@[NSStringFromSelector(invocation.selector)]];
		if (0 == strcmp(invocation.methodSignature.methodReturnType, @encode(id))) {
			id returnValue = self;
			[invocation setReturnValue:&returnValue];
		}
		else {
			abort();
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
