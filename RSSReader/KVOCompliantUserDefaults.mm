//
//  KVOCompliantUserDefaults.m
//  RSSReader
//
//  Created by Grigory Entin on 25.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KVOCompliantUserDefaults.h"
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSString.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSKeyValueObserving.h>
#import <objc/runtime.h>
#import <stdlib.h>
#import <sys/types.h>
#import <assert.h>

#define let auto const
#define var auto

var _1 = 1;
var _0 = 0;

id boxed(NSObject *value) {
	return value;
}

id boxed(BOOL value) {
	return @(value);
}

#define _(...) ^{ \
	let $ = __VA_ARGS__; \
	if (_0) { \
		NSLog(@"%s: %@", #__VA_ARGS__, boxed(__VA_ARGS__)); \
	} \
	return $; \
}()

template <typename T>
T *
as(id object) {
	if (!object || [object isKindOfClass:[T class]]) {
		return object;
	}
	else {
		abort();
	}
}
@interface KVOCompliantUserDefaults ()

@property (strong, nonatomic) NSMutableDictionary *values;
@property (strong, nonatomic) NSUserDefaults *defaults;

@end

@implementation KVOCompliantUserDefaults

static NSDictionary *
propertyInfoFromProperty(objc_property_t property) {
	let name = property_getName(property);
	let attributes = property_getAttributes(property);
	let attributesDictionary = ^{
		var attributesCount = unsigned(0);
		let attributesList = property_copyAttributeList(property, &attributesCount);
		let $ = [NSMutableDictionary new];
		for (var i = 0; i < attributesCount; ++i) {
			let attribute = attributesList[0];
			$[@(attribute.name)] = @(attribute.value);
		}
		free(attributesList);
		return $;
	}();
	let $ = [NSMutableDictionary new];
	$[@"name"] = @(name);
	$[@"attributes"] = @(attributes);
	$[@"attributesList"] = attributesDictionary;
	return $;
}

+ (NSDictionary *)propertyInfos {
	let $ = [NSMutableDictionary new];
	var propertyCount = unsigned(0);
	let propertyList = class_copyPropertyList(self, &propertyCount);
	for (var i = 0; i < propertyCount; ++i) {
		let property = propertyList[i];
		let propertyInfo = propertyInfoFromProperty(property);
		$[propertyInfo[@"name"]] = propertyInfo;
	}
	free(propertyList);
	return $;
}

- (BOOL)isDefaultName:(NSString *)name;
{
	return ![@[@"values", @"defaults"] containsObject:name];
}

- (void)synchronizeValues {
	let propertyInfos = self.class.propertyInfos;
	for (NSString *propertyName in propertyInfos.allKeys) {
		let values = self.values;
		let defaults = self.defaults;
		let propertyInfo = as<NSDictionary>(propertyInfos[propertyName]);
		if ([self isDefaultName:propertyInfo[@"name"]]) {
			let oldValue = as<NSObject>(values[propertyName]);
			let newValue = as<NSObject>([defaults objectForKey:propertyName]);
			if (oldValue == newValue) {
			}
			else if ([oldValue isEqual:newValue]) {
			}
			else {
				[self willChangeValueForKey:propertyName];
				values[propertyName] = newValue;
				[self didChangeValueForKey:propertyName];
			}
		}
	}
}

#pragma mark -

static
id
objectValueIMP(KVOCompliantUserDefaults *self, SEL _cmd) {
	let propertyName = NSStringFromSelector(_cmd);
	let value = as<NSObject>(self.values[propertyName]);
	(void)_(propertyName);
	return _(value);
}

static
BOOL
boolValueIMP(KVOCompliantUserDefaults *self, SEL _cmd) {
	let propertyName = NSStringFromSelector(_cmd);
	let value = [self.values[propertyName] boolValue];
	(void)_(propertyName);
	return _(value);
}

#pragma mark -

+ (BOOL)resolveInstanceMethod:(SEL)sel {
	let propertyInfos = self.class.propertyInfos;
	let selName = NSStringFromSelector(sel);
	if (let propertyInfo = as<NSDictionary>(propertyInfos[selName])) {
		(void)_(propertyInfo);
		let attributes = as<NSDictionary>(propertyInfo[@"attributesList"]);
		let type = as<NSString>(attributes[@"T"]);
		let methodsByType = @{
			@(@encode(BOOL)): [NSValue valueWithPointer:(void const *)boolValueIMP],
			@(@encode(id)): [NSValue valueWithPointer:(void const *)objectValueIMP]
		};
		let methodIMP = IMP(as<NSValue>(methodsByType[[type substringToIndex:1]]).pointerValue);
		assert(methodIMP);
		class_addMethod([self class], sel, methodIMP, "@@:");
		return YES;
	}
	return [super resolveInstanceMethod:sel];
}

#pragma mark -

- (id)init {
	if (!(self = [super init])) {
		return self;
	}
	self.values = [NSMutableDictionary new];
	let defaults = [NSUserDefaults standardUserDefaults];
	let notificationCenter = NSNotificationCenter.defaultCenter;
	__block var handlingNotification = false;
	[notificationCenter addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
		if (!handlingNotification) {
			handlingNotification = true;
			[defaults synchronize];
			[self synchronizeValues];
			handlingNotification = false;
		}
	}];
	self.defaults = defaults;
	[self synchronizeValues];
	return self;
}

@end
