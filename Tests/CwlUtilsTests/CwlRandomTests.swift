//
//  CwlRandomTests.swift
//  CwlUtils
//
//  Created by Matt Gallagher on 2016/05/17.
//  Copyright © 2016 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation
import XCTest
import CwlUtils

#if SWIFT_PACKAGE
import ReferenceRandomGenerators
#endif

let VerificationIterations = 1000

class RandomTests: XCTestCase {
	func genericTest<Generator: RandomGenerator>(generator: inout Generator, testUnique: Bool = true) {
		let a = generator.random64()
		let b = generator.random64()
		let c = generator.random64()
		let d = generator.random64()
		
		if testUnique {
			XCTAssert(a != b && a != c && a != d && b != c && b != d && c != d, "Technically, we *could* get a collision...")
		}
		
		let e = generator.random32()
		XCTAssert(type(of: e) == UInt32.self)
		
		let f = generator.random64(max: 1)
		XCTAssert(f < 2)
		
		let g = generator.random32(max: 1)
		XCTAssert(g < 2)
		
		// More rigorous testing on these would be nice but for now, at least run them
		_ = generator.random64(max: UInt64.max)
		_ = generator.randomHalfOpen()
		_ = generator.randomClosed()
		_ = generator.randomOpen()
	}
	
	func testDevRandom() {
		var generator = DevRandom()
		genericTest(generator: &generator)
	}
	
	func testArc4Random() {
		var generator = Arc4Random()
		genericTest(generator: &generator)
	}
	
	func testLfsr258() {
		var generator = Lfsr258()
		genericTest(generator: &generator)
	}
	
	func testLfsr176() {
		var generator = Lfsr176()
		genericTest(generator: &generator)
	}
	
	func testConstantNonRandom() {
		var generator = ConstantNonRandom()
		genericTest(generator: &generator, testUnique: false)
	}
	
	func testXoroshiro() {
		var generator = Xoroshiro()
		genericTest(generator: &generator)
		
		// Test Xoroshiro against the reference implementation to verify output
		var g1 = Xoroshiro(seed: (12345678, 87654321))
		var g2 = xoroshiro128plus(seed: (12345678, 87654321))
		for _ in 0..<VerificationIterations {
			XCTAssert(g1.random64() == g2.random64())
		}
	}
	
	func testXoroshiro128plus() {
		var generator = xoroshiro128plus()
		genericTest(generator: &generator)
	}
	
	func testMersenneTwister() {
		var generator = MersenneTwister()
		genericTest(generator: &generator)
		
		// Test MersenneTwister against the reference implementation to verify output
		var g1 = MersenneTwister(seed: 12345678)
		var g2 = MT19937_64(seed: 12345678)
		for _ in 0..<VerificationIterations {
			XCTAssert(g1.random64() == g2.random64())
		}
	}
	
	func testMT19937_64() {
		var generator = MT19937_64()
		genericTest(generator: &generator)
	}
}

// NOTE: I've moved the `ConstantNonRandom` and the two `Lfsr` implementations here. They're not advised for any common usage and I retain them here purely for performance comparison

public struct ConstantNonRandom: RandomWordGenerator {
	public typealias WordType = UInt64
	var state: UInt64 = DevRandom.random64()

	public init() {
	}

	public init(seed: UInt64) {
		self.state = seed
	}

	public mutating func random64() -> UInt64 {
		return randomWord()
	}

	public mutating func randomWord() -> UInt64 {
		return state
	}
}

public struct Lfsr258: RandomWordGenerator {
	public typealias WordType = UInt64
	public typealias StateType = (UInt64, UInt64, UInt64, UInt64, UInt64)

	static let k: (UInt64, UInt64, UInt64, UInt64, UInt64) = (1, 9, 12, 17, 23)
	static let q: (UInt64, UInt64, UInt64, UInt64, UInt64) = (1, 24, 3, 5, 3)
	static let s: (UInt64, UInt64, UInt64, UInt64, UInt64) = (10, 5, 29, 23, 8)

	var state: StateType = (0, 0, 0, 0, 0)

	public init() {
		var r = DevRandom()
		repeat {
			r.randomize(buffer: &state.0, size: MemoryLayout<UInt64>.size)
		} while state.0 < Lfsr258.k.0
		repeat {
			r.randomize(buffer: &state.1, size: MemoryLayout<UInt64>.size)
		} while state.1 < Lfsr258.k.1
		repeat {
			r.randomize(buffer: &state.2, size: MemoryLayout<UInt64>.size)
		} while state.2 < Lfsr258.k.2
		repeat {
			r.randomize(buffer: &state.3, size: MemoryLayout<UInt64>.size)
		} while state.3 < Lfsr258.k.3
		repeat {
			r.randomize(buffer: &state.4, size: MemoryLayout<UInt64>.size)
		} while state.4 < Lfsr258.k.4
	}
	
	public init(seed: StateType) {
		self.state = seed
	}
	
	public mutating func randomWord() -> UInt64 {
		return random64()
	}

	public mutating func random64() -> UInt64 {
		// Constants from "Tables of Maximally-Equidistributed Combined LFSR Generators" by Pierre L'Ecuyer:
		// http://www.iro.umontreal.ca/~lecuyer/myftp/papers/tausme2.ps
		let l: UInt64 = 64
		let x0 = (((state.0 << Lfsr258.q.0) ^ state.0) >> (l - Lfsr258.k.0 - Lfsr258.s.0))
		state.0 = ((state.0 & (UInt64.max << Lfsr258.k.0)) << Lfsr258.s.0) | x0
		let x1 = (((state.1 << Lfsr258.q.1) ^ state.1) >> (l - Lfsr258.k.1 - Lfsr258.s.1))
		state.1 = ((state.1 & (UInt64.max << Lfsr258.k.1)) << Lfsr258.s.1) | x1
		let x2 = (((state.2 << Lfsr258.q.2) ^ state.2) >> (l - Lfsr258.k.2 - Lfsr258.s.2))
		state.2 = ((state.2 & (UInt64.max << Lfsr258.k.2)) << Lfsr258.s.2) | x2
		let x3 = (((state.3 << Lfsr258.q.3) ^ state.3) >> (l - Lfsr258.k.3 - Lfsr258.s.3))
		state.3 = ((state.3 & (UInt64.max << Lfsr258.k.3)) << Lfsr258.s.3) | x3
		let x4 = (((state.4 << Lfsr258.q.4) ^ state.4) >> (l - Lfsr258.k.4 - Lfsr258.s.4))
		state.4 = ((state.4 & (UInt64.max << Lfsr258.k.4)) << Lfsr258.s.4) | x4
		return (state.0 ^ state.1 ^ state.2 ^ state.3 ^ state.4)
	}
}

public struct Lfsr176: RandomWordGenerator {
	public typealias WordType = UInt64
	public typealias StateType = (UInt64, UInt64, UInt64)

	static let k: (UInt64, UInt64, UInt64) = (1, 6, 9)
	static let q: (UInt64, UInt64, UInt64) = (5, 19, 24)
	static let s: (UInt64, UInt64, UInt64) = (24, 13, 17)

	var state: StateType = (0, 0, 0)

	public init() {
		var r = DevRandom()
		repeat {
			r.randomize(buffer: &state.0, size: MemoryLayout<UInt64>.size)
		} while state.0 < Lfsr176.k.0
		repeat {
			r.randomize(buffer: &state.1, size: MemoryLayout<UInt64>.size)
		} while state.1 < Lfsr176.k.1
		repeat {
			r.randomize(buffer: &state.2, size: MemoryLayout<UInt64>.size)
		} while state.2 < Lfsr176.k.2
	}
	
	public init(seed: StateType) {
		self.state = seed
	}
	
	public mutating func random64() -> UInt64 {
		return randomWord()
	}

	public mutating func randomWord() -> UInt64 {
		// Constants from "Tables of Maximally-Equidistributed Combined LFSR Generators" by Pierre L'Ecuyer:
		// http://www.iro.umontreal.ca/~lecuyer/myftp/papers/tausme2.ps
		let l: UInt64 = 64
		let x0 = (((state.0 << Lfsr176.q.0) ^ state.0) >> (l - Lfsr176.k.0 - Lfsr176.s.0))
		state.0 = ((state.0 & (UInt64.max << Lfsr176.k.0)) << Lfsr176.s.0) | x0
		let x1 = (((state.1 << Lfsr176.q.1) ^ state.1) >> (l - Lfsr176.k.1 - Lfsr176.s.1))
		state.1 = ((state.1 & (UInt64.max << Lfsr176.k.1)) << Lfsr176.s.1) | x1
		let x2 = (((state.2 << Lfsr176.q.2) ^ state.2) >> (l - Lfsr176.k.2 - Lfsr176.s.2))
		state.2 = ((state.2 & (UInt64.max << Lfsr176.k.2)) << Lfsr176.s.2) | x2
		return (state.0 ^ state.1 ^ state.2)
	}
}


//
// NOTE: the following two implementations are duplicated in CwlRandomPerformanceTests.swift and in CwlRandomTests.swift file.
// The reason for this duplication is that CwlRandomPerformanceTests.swift is normally excluded from the build, so CwlRandomTests.swift can't rely on it. But CwlRandomPerformanceTests.swift needs these structs included locally because they need to be inlined (to make the performance comparison fair) and whole module optimization is disabled for this testing bundle (to allow testing across module boundaries where desired).
//

private struct MT19937_64: RandomWordGenerator {
	typealias WordType = UInt64
	var state = mt19937_64()
	
	init() {
		init_genrand64(&state, DevRandom.random64())
	}
	
	init(seed: UInt64) {
		init_genrand64(&state, seed)
	}
	
	mutating func random64() -> UInt64 {
		return genrand64_int64(&state)
	}
	
	mutating func randomWord() -> UInt64 {
		return genrand64_int64(&state)
	}
}

private struct xoroshiro128plus: RandomWordGenerator {
	typealias WordType = UInt64
	var state = xoroshiro_state(s: (DevRandom.random64(), DevRandom.random64()))
	
	init() {
	}
	
	init(seed: (UInt64, UInt64)) {
		self.state.s = seed
	}
	
	mutating func random64() -> UInt64 {
		return xoroshiro_next(&state)
	}
	
	mutating func randomWord() -> UInt64 {
		return xoroshiro_next(&state)
	}
}

