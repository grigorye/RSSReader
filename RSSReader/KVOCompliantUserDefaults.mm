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
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSKeyValueObserving.h>
#import <objc/runtime.h>
#import <stdlib.h>
#import <assert.h>
#import <ctype.h>

#define let auto const
#define var auto

var _1 = 1;
var _0 = 0;

id boxed(NSObject *value) {
	return value;
}

__nonnull id boxed(BOOL value) {
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

template <typename T>
T *
nnil(T *object) {
	assert(object);
	return object;
}

@interface KVOCompliantUserDefaults ()

@property (strong, nonatomic) NSMutableDictionary *values;
@property (strong, nonatomic) NSUserDefaults *defaults;

@end

@implementation KVOCompliantUserDefaults

static __nonnull NSDictionary *
propertyInfoFromProperty(objc_property_t property) {
	let name = property_getName(property);
	let attributes = property_getAttributes(property);
	let attributesDictionary = ^{
		var attributesCount = unsigned(0);
		let attributesList = property_copyAttributeList(property, &attributesCount);
		let $ = [NSMutableDictionary new];
		for (var i = 0; i < attributesCount; ++i) {
			let attribute = attributesList[i];
			$[@(attribute.name)] = @(attribute.value);
		}
		free(attributesList);
		return $;
	}();
	let $ = [NSMutableDictionary new];
	$[@"name"] = @(name);
	$[@"attributes"] = @(attributes);
	$[@"attributesDictionary"] = attributesDictionary;
	return $;
}

+ (nonnull NSDictionary *)propertyInfosWithGetterAndSetterMap:(NSMutableDictionary * __autoreleasing *)getterAndSetterMapP {
	let $ = [NSMutableDictionary new];
	let getterAndSetterMap = [NSMutableDictionary new];
	var propertyCount = unsigned(0);
	let propertyList = class_copyPropertyList(self, &propertyCount);
	for (var i = 0; i < propertyCount; ++i) {
		let property = propertyList[i];
		let propertyInfo = propertyInfoFromProperty(property);
		let attributesDictionary = as<NSDictionary>(nnil(propertyInfo[@"attributesDictionary"]));
		let propertyName = as<NSString>(nnil(propertyInfo[@"name"]));
		let customSetterName = as<NSString>(attributesDictionary[@"S"]);
		let customGetterName = as<NSString>(attributesDictionary[@"G"]);
		let defaultGetterName = propertyName;
		let defaultSetterName = [NSString stringWithFormat:@"set%c%@:", toupper([propertyName characterAtIndex:0]), [propertyName substringFromIndex:1]];
		getterAndSetterMap[customGetterName ?: defaultGetterName] = propertyInfo;
		getterAndSetterMap[customSetterName ?: defaultSetterName] = propertyInfo;
		$[propertyName] = propertyInfo;
	}
	free(propertyList);
	*getterAndSetterMapP = getterAndSetterMap;
	return $;
}

- (BOOL)isDefaultName:(nonnull NSString *)name;
{
	return ![@[@"values", @"defaults"] containsObject:name];
}

#pragma mark -

+ (nonnull NSDictionary *)propertyInfos;
{
	NSMutableDictionary *propertyInfoGetterAndSetterMap;
	return [self propertyInfosWithGetterAndSetterMap:&propertyInfoGetterAndSetterMap];
}

+ (nonnull NSDictionary *)propertyInfoGetterAndSetterMap;
{
	NSMutableDictionary *_;
	(void)[self propertyInfosWithGetterAndSetterMap:&_];
	return _;
}

#pragma mark -

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
void
setObjectValueIMP(KVOCompliantUserDefaults *self, SEL _cmd, id value) {
	let defaultName = [self.class defaultNameForSelector:_cmd];
	[self.defaults setObject:value forKey:_(defaultName)];
	self.values[defaultName] = value;
}

static
BOOL
boolValueIMP(KVOCompliantUserDefaults *self, SEL _cmd) {
	let propertyName = NSStringFromSelector(_cmd);
	let value = [self.values[propertyName] boolValue];
	(void)_(propertyName);
	return _(value);
}

static
void
setBoolValueIMP(KVOCompliantUserDefaults *self, SEL _cmd, BOOL value) {
	let propertyName = NSStringFromSelector(_cmd);
	(void)_(propertyName);
	[self.defaults setBool:value forKey:propertyName];
	self.values[propertyName] = @(value);
}

#pragma mark -

+ (nonnull NSString *)defaultNameForSelector:(SEL)sel;
{
	let selName = NSStringFromSelector(sel);
	let propertyInfo = as<NSDictionary>(self.propertyInfoGetterAndSetterMap[selName]);
	(void)_(propertyInfo);
	let defaultName = as<NSString>(propertyInfo[@"name"]);
	return defaultName;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
	let propertyInfoGetterAndSetterMap = self.class.propertyInfoGetterAndSetterMap;
	let selName = NSStringFromSelector(sel);
	if (let propertyInfo = as<NSDictionary>(propertyInfoGetterAndSetterMap[selName])) {
		(void)_(propertyInfo);
		let attributesDictionary = as<NSDictionary>(propertyInfo[@"attributesDictionary"]);
		let type = as<NSString>(attributesDictionary[@"T"]);
		let isSetter = [selName hasSuffix:@":"];
		let methodsByType = isSetter ? @{
			@(@encode(BOOL)): [NSValue valueWithPointer:(void const *)setBoolValueIMP],
			@(@encode(id)): [NSValue valueWithPointer:(void const *)setObjectValueIMP]
		} : @{
			@(@encode(BOOL)): [NSValue valueWithPointer:(void const *)boolValueIMP],
			@(@encode(id)): [NSValue valueWithPointer:(void const *)objectValueIMP]
		};
		let valueTypeEncoded = [type substringToIndex:1];
		let methodIMP = IMP(as<NSValue>(methodsByType[[type substringToIndex:1]]).pointerValue);
		assert(methodIMP);
		let types = isSetter ? [NSString stringWithFormat:@"v@:%@", valueTypeEncoded] : [NSString stringWithFormat:@"%@@:", valueTypeEncoded];
		class_addMethod([self class], sel, methodIMP, types.UTF8String);
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
