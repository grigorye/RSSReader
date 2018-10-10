//
//  BadInstructionAwareTestCase.swift
//  RSSReaderDataTests
//
//  Created by Grigory Entin on 16.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import XCTest
#if USE_POSIX_SIGNALS
	import CwlPreconditionTesting_POSIX
#else
	import CwlPreconditionTesting
#endif

extension XCTestCase {
	
	@objc public func badInstructionAwareInvokeTest() {
		
		let badInstructionException = catchBadInstruction {
			
			/// Swizzled invokeTest
            self.badInstructionAwareInvokeTest()
		}
        [badInstructionException].compactMap { $0 }.forEach {
			recordFailure(withDescription: "\($0)", inFile: #file, atLine: #line, expected: false)
		}
	}
}
