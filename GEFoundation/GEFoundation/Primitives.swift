//
//  Primitives.swift
//  GEBase
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

public var _1 = true
public var _0 = false

public typealias Handler = () -> Void

private func performAndDropEachReversed(_ array: inout [Handler]) {
	for _ in 0..<array.count {
		let handler = array.last!
		handler()
		array = Array(array.dropLast(1))
	}
}

public struct ScheduledHandlers {

	var handlers = [Handler]()
	
	public mutating func perform() {
		performAndDropEachReversed(&handlers)
	}
	
	public init() {}
	
}

public func += (handlers: ScheduledHandlers, _ extraHandlers: [Handler]) {
	handlers += extraHandlers
}

