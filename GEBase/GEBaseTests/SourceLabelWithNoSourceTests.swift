//
//  SourceLabelWithNoSourceTests.swift
//  GEBase
//
//  Created by Grigory Entin on 22.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

@testable import GEBase
import XCTest

class SourceLabelWithNoSourceTests : TraceAndLabelTestsBase {
	func testSimple() {
		traceLabelsEnabledEnforced = true
		let s = "foo"
		let sourceFilename = URL(fileURLWithPath: #file).lastPathComponent
		let bundleFilename = Bundle(for: SourceLabelWithNoSourceTests.self).bundleURL.lastPathComponent
		let cln = #column
		let l = L(s)
		XCTAssertEqual(l, "\(bundleFilename)/\(sourceFilename)[!exist]:\(cln):?: foo")
	}
}
