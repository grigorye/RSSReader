/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAllocationTrackerGeneration.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "FBAllocationTrackerNSZombieSupport.h"

static size_t _allocationNumber = 0;

namespace FB { namespace AllocationTracker {
  
  size_t allocationNumber() {
    return _allocationNumber;
  }
  
  void Generation::add(__unsafe_unretained id object) {
    Class aCls = [object class];
    objects[aCls][object] = _allocationNumber++;
  }

  void Generation::remove(__unsafe_unretained id object) {
    Class aCls = [object class];
    objects[aCls].erase(object);
  }

  GenerationSummary Generation::getSummary() const {
    GenerationSummary summary;

    for (const auto &kv: objects) {
      Class aCls = kv.first;
      const GenerationList &list = kv.second;

      NSInteger count = list.size();

      summary[aCls] = count;
    }

    return summary;
  }

  GenerationEntries Generation::entriesForClass(__unsafe_unretained Class aCls, size_t maxAllocNumber) const {
    std::vector<GenerationEntry> returnValue;

    const GenerationMap::const_iterator obj = objects.find(aCls);
    size_t minAllocNumber = SIZE_T_MAX;
    if (obj != objects.end()) {
      const GenerationList &list = obj->second;
      for (const auto &object_pair: list) {
        __weak id weakObject = nil;
        __weak id object = object_pair.first;
        size_t allocNumber = object_pair.second;
        if (maxAllocNumber < allocNumber) {
          continue;
        }
        minAllocNumber = std::min(allocNumber, minAllocNumber);

        BOOL (*allowsWeakReference)(id, SEL) =
        (__typeof__(allowsWeakReference))class_getMethodImplementation(aCls, @selector(allowsWeakReference));

        if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
          if (allowsWeakReference(object, @selector(allowsWeakReference))) {
            // This is still racey since allowsWeakReference could change it value by now.
            weakObject = object;
          }
        } else {
          weakObject = object;
        }

        /**
         Retain object and add it to returnValue.
         This operation can be unsafe since we are retaining object that could
         be deallocated on other thread.

         When NSZombie enabled, we can find if object has been deallocated by checking its class name.
         */
        if (!fb_isZombieObject(weakObject)) {
          returnValue.push_back(GenerationEntry(weakObject, allocNumber));
        }
      }
    }

    return GenerationEntries(returnValue, minAllocNumber);
  }

} }
