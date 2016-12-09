//
//  TypeFilteringActivity.swift
//  GEBase
//
//  Created by Grigory Entin on 01.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit.UIActivity

public protocol ActivityItemsFilter {
	func canPerformWithActivityItems(_ activityItems: [Any]) -> Bool
	func prepareWithActivityItems(_ activityItems: [Any])
}

public class TypeBasedActivityItemsFilter<T> : ActivityItemsFilter {
	public var acceptedItems: [T]! = nil
	public func canPerformWithActivityItems(_ activityItems: [Any]) -> Bool {
		let acceptableItems = filterObjectsByType(activityItems) as [T]
		return acceptableItems.count != 0
	}
	public func prepareWithActivityItems(_ activityItems: [Any]) {
		let acceptableItems = filterObjectsByType(activityItems) as [T]
		self.acceptedItems = acceptableItems
	}
	public init() {}
}

open class TypeFilteringActivity : UIActivity {
	let untypedItemsFilter: ActivityItemsFilter
	override open func canPerform(withActivityItems activityItems: [Any]) -> Bool {
		return untypedItemsFilter.canPerformWithActivityItems(activityItems)
	}
	override open func prepare(withActivityItems activityItems: [Any]) {
		untypedItemsFilter.prepareWithActivityItems(activityItems)
	}
	public init(untypedItemsFilter: ActivityItemsFilter) {
		self.untypedItemsFilter = untypedItemsFilter
		super.init()
	}
}
