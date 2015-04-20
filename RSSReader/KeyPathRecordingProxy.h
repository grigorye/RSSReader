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

#ifdef __cplusplus
extern "C" {
#endif
Class object_setClassAndRetain(id object, Class cls);
#ifdef __cplusplus
}
#endif

extern void const *keyPathRecorderProxyAssociation;
extern NSUInteger keyPathRecordingProxyLiveCount;
