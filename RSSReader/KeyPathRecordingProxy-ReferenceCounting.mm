//
//  KeyPathRecordingProxy-ReferenceCounting.mm
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KeyPathRecordingProxy-ReferenceCounting.h"
#import <objc/runtime.h>

#define let auto const
#define var auto

Class object_setClassAndRetain(id object, Class cls) {
	let oldClass = object_setClass(object, cls);
	[object retain];
	return oldClass;
}
