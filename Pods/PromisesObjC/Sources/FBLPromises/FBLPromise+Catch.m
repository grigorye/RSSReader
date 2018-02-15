/**
 Copyright 2018 Google Inc. All rights reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at:

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "FBLPromise+Catch.h"

#import "FBLPromisePrivate.h"

@implementation FBLPromise (CatchAdditions)

- (FBLPromise *)catch:(FBLPromiseCatchBlock)reject {
  return [self onQueue:dispatch_get_main_queue() catch:reject];
}

- (FBLPromise *)onQueue:(dispatch_queue_t)queue catch:(FBLPromiseCatchBlock)reject {
  NSParameterAssert(reject);

  return [self chainOnQueue:queue
             chainedFulfill:nil
              chainedReject:^id(NSError *error) {
                reject(error);
                return error;
              }];
}

@end

@implementation FBLPromise (DotSyntax_CatchAdditions)

- (FBLPromise* (^)(FBLPromiseCatchBlock))catch {
  return ^(FBLPromiseCatchBlock catch) {
    return [self catch:catch];
  };
}

- (FBLPromise* (^)(dispatch_queue_t, FBLPromiseCatchBlock))catchOn {
  return ^(dispatch_queue_t queue, FBLPromiseCatchBlock catch) {
    return [self onQueue:queue catch:catch];
  };
}

@end
