//
//  KVOCompliantUserDefaults.m
//  RSSReader
//
//  Created by Grigory Entin on 25.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KVOCompliantUserDefaults.h"
#import <GEBase/ObjCPrimitives.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSKeyValueObserving.h>
#import <objc/runtime.h>
#import <stdlib.h>
#import <assert.h>
#import <ctype.h>


@interface KVOCompliantUserDefaults ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, NSObject *> *values;
@property (strong, nonatomic) NSUserDefaults *defaults;

@end

@interface PropertyInfo : NSObject {}

@property (copy, nonatomic, nonnull) NSString *name;
@property (copy, nonatomic) NSString *attributes;
@property (copy, nonatomic, nonnull) NSDictionary<NSString *, NSString *> *attributesDictionary;

@end
@implementation PropertyInfo
@end

@implementation KVOCompliantUserDefaults

static PropertyInfo * __nonnull
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
	let $ = [PropertyInfo new];
	$.name = @(name);
	$.attributes = @(attributes);
	$.attributesDictionary = attributesDictionary;
	return $;
}

+ (nonnull NSDictionary<NSString *, PropertyInfo *> *)propertyInfosWithGetterAndSetterMap:(NSMutableDictionary * __autoreleasing *)getterAndSetterMapP {
	let $ = [NSMutableDictionary new];
	let getterAndSetterMap = [NSMutableDictionary new];
	var propertyCount = unsigned(0);
	let propertyList = class_copyPropertyList(self, &propertyCount);
	for (var i = 0; i < propertyCount; ++i) {
		let property = propertyList[i];
		let propertyInfo = propertyInfoFromProperty(property);
		let attributesDictionary = propertyInfo.attributesDictionary;
		let propertyName = propertyInfo.name;
		let customSetterName = attributesDictionary[@"S"];
		let customGetterName = attributesDictionary[@"G"];
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

+ (nonnull NSDictionary<NSString *, PropertyInfo *> *)propertyInfos;
{
	NSMutableDictionary *propertyInfoGetterAndSetterMap;
	return [self propertyInfosWithGetterAndSetterMap:&propertyInfoGetterAndSetterMap];
}

+ (nonnull NSDictionary<NSString *, PropertyInfo *> *)propertyInfoGetterAndSetterMap;
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
		let propertyInfo = propertyInfos[propertyName];
		if ([self isDefaultName:propertyInfo.name]) {
			let oldValue = values[propertyName];
			let newValue = as<NSObject>([defaults objectForKey:propertyName]);
			if (oldValue == newValue) {
			}
			else if ([oldValue isEqual:newValue]) {
			}
			else {
				[self willChangeValueForKey:propertyName];
				if (newValue) {
					values[propertyName] = newValue;
				}
				else {
					[values removeObjectForKey:propertyName];
				}
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
	let value = self.values[propertyName];
	(void)_(propertyName);
	return _(value);
}

static
void
setObjectValueIMP(KVOCompliantUserDefaults *self, SEL _cmd, id value) {
	let defaultName = [self.class defaultNameForSelector:_cmd];
	[self.defaults setObject:value forKey:_(defaultName)];
	if (value) {
		self.values[defaultName] = value;
	}
	else {
		[self.values removeObjectForKey:defaultName];
	}
}

static
BOOL
boolValueIMP(KVOCompliantUserDefaults *self, SEL _cmd) {
	let propertyName = NSStringFromSelector(_cmd);
	let value = [(id)self.values[propertyName] boolValue];
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
	let propertyInfo = self.propertyInfoGetterAndSetterMap[selName];
	(void)_(propertyInfo);
	let defaultName = propertyInfo.name;
	return defaultName;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
	let propertyInfoGetterAndSetterMap = self.class.propertyInfoGetterAndSetterMap;
	let selName = NSStringFromSelector(sel);
	if (let propertyInfo = propertyInfoGetterAndSetterMap[selName]) {
		(void)_(propertyInfo);
		let attributesDictionary = propertyInfo.attributesDictionary;
		let type = attributesDictionary[@"T"];
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
