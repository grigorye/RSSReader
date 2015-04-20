//
//  KeyPathRecordingProxy.h
//  RSSReader
//
//  Created by Grigory Entin on 17.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyPathRecordingProxy : NSProxy

@property (strong, nonatomic) Class valueClass;
@property (copy, nonatomic) NSArray *keyPathComponents;

@end

extern NSUInteger keyPathRecordingProxyLiveCount;
