//
//  KeyPathRecordingProxy.h
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyPathRecordingProxy : NSProxy

@property (nonatomic) NSUInteger proxyRetainCount;
@property (strong, nonatomic) NSObject *fakeReturnValue;
@property (strong, nonatomic) Class realObjectClass;
@property (copy, nonatomic) NSArray *keyPathComponents;

@end

extern void const *keyPathRecorderProxyAssociation;
