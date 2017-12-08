/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAllocationTrackerGenerationManager.h"

namespace FB { namespace AllocationTracker {
  
  size_t allocationNumber();
  
  void GenerationManager::markGeneration() {
    generations.emplace_back(Generation {});
  }

  void GenerationManager::addObject(__unsafe_unretained id object){
    NSInteger numberOfGenerations = generations.size();
    if (numberOfGenerations == 0) {
      return;
    }

    Generation &lastGeneration = generations.back();
    generationMapping[object] = numberOfGenerations - 1;

    lastGeneration.add(object);
  }

  void GenerationManager::removeObject(__unsafe_unretained id object) {
    auto it = generationMapping.find(object);
    if (it == generationMapping.end()) {
      return;
    }
    NSInteger generationNumber = it->second;

    Generation &generation = generations[generationNumber];
    generation.remove(object);

    generationMapping.erase(object);
  }

  FullGenerationSummary GenerationManager::summary() const {
    FullGenerationSummary fullSummary;

    for (const auto &generation: generations) {
      fullSummary.push_back(generation.getSummary());
    }

    return fullSummary;
  }

  GenerationEntries GenerationManager::entriesForClassInGeneration(__unsafe_unretained Class aCls,
                                                                   size_t generationIndex,
                                                                   size_t maxAllocNumber) {
    const Generation &givenGeneration = generations[generationIndex];
    return givenGeneration.entriesForClass(aCls, maxAllocNumber);
  }

  GenerationEntries GenerationManager::entriesForClassInLastGeneration(__unsafe_unretained Class aCls, size_t maxAllocNumber) {
    size_t generationIndex = generations.size() - 1;
    return entriesForClassInGeneration(aCls, generationIndex, maxAllocNumber);
  }
} }
