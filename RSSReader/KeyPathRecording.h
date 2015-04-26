//
//  KeyPathRecording.h
//  RSSReader
//
//  Created by Grigory Entin on 24.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

NSString *recordKeyPath(void (^recorder)(NSObject *));

#ifdef __cplusplus
}
#endif
