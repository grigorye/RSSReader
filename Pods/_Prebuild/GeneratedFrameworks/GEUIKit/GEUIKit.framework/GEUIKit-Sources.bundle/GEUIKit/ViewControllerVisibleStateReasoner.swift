//
//  ViewControllerVisibleStateReasoner.swift
//  GEUIKit
//
//  Created by Grigory Entin on 18.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public struct ViewControllerVisibleStateReasoner {
	
	private (set) public var appeared = false
	private (set) public var transitioning = false
	
	public mutating func viewDidAppear() {
		precondition(transitioning)
		transitioning = false
		guard !appeared else {
			return
		}
		appeared = true
	}
	
	public mutating func viewDidDisappear() {
		precondition(transitioning)
		transitioning = false
		guard appeared else {
			return
		}
		appeared = false
	}
	
	public mutating func viewWillAppear() {
		guard !transitioning else {
			return
		}
		transitioning = true
	}
	
	public mutating func viewWillDisappear() {
		guard !transitioning else {
			return
		}
		transitioning = true
	}

	public init() {}

}
