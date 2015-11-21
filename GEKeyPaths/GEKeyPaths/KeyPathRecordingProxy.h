//
//  KeyPathRecordingProxy.h
//  GEKeyPaths
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <Foundation/NSProxy.h>
#import <Foundation/NSArray.h>

@interface KeyPathRecordingProxy : NSProxy

@property (copy, nonatomic) NSArray<NSString *> * _Nonnull keyPathComponents;

+ (instancetype _Nonnull)newProxy;

@end

extern NSUInteger keyPathRecordingProxyLiveCount;
