//
//  ObjCPrimitives.h
//  GEBase
//
//  Created by Grigory Entin on 02.08.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

#import <Foundation/NSValue.h>
#import <objc/objc.h>
#import <stdlib.h>

@class NSObject;

#define let auto const
#define var auto

extern int _1;
extern int _0;

#ifdef __cplusplus

inline
id boxed(NSObject * value) {
	return value;
}

inline
id boxed(BOOL value) {
	return @(value);
}

template <typename T>
T const &
trace(T const &value, const char *literal) {
	if (_1) {
		NSLog(@"%s: %@", literal, boxed(value));
	}
	return value;
}

#define _(...) trace(__VA_ARGS__, #__VA_ARGS__)

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

#endif
