//
//  KeyPathRecording.m
//  RSSReader
//
//  Created by Grigory Entin on 24.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import "KeyPathRecording.h"
#import "KeyPathRecordingProxy.h"

#define let auto const
#define var auto

NSString *recordKeyPath(void (^recorder)(NSObject *))
{
	let proxy = [KeyPathRecordingProxy alloc];
	recorder((id)proxy);
	let keyPath = [proxy.keyPathComponents componentsJoinedByString:@"."];
	return keyPath;
}
