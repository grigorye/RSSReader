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

void const *keyPathRecorderProxyAssociation = &keyPathRecorderProxyAssociation;

@implementation KeyPathRecordingProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [NSObject instanceMethodSignatureForSelector:@selector(description)];
}

+ (BOOL)respondsToSelector:(SEL)aSelector;
{
	return YES;
}

- (void)forwardInvocation:(NSInvocation *)invocation;
{
	SEL selector = invocation.selector;
	if (sel_isEqual(selector, @selector(copy))) {
		id returnValue = nil;
		[invocation setReturnValue:&returnValue];
		return;
	}
	KeyPathRecordingProxy *proxy = objc_getAssociatedObject(self, keyPathRecorderProxyAssociation);
	{
		proxy.keyPathComponents = [[NSArray arrayWithArray:proxy.keyPathComponents] arrayByAddingObjectsFromArray:@[NSStringFromSelector(invocation.selector)]];
		let property = class_getProperty(proxy.realObjectClass, sel_getName(selector));
		let propertyType = property_copyAttributeValue(property, "T");
		if (0 == strcmp(propertyType, @encode(id))) {
			var returnValue = proxy.fakeReturnValue;
			[invocation setReturnValue:&returnValue];
		}
		else {
			id returnValue = self;
			[invocation setReturnValue:&returnValue];
		}
	}
}

#pragma mark -

- (void)dealloc;
{
}

@end
