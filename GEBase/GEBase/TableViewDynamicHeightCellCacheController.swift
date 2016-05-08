
//
//  TableViewDynamicHeightCellEstimator.swift
//  GEBase
//
//  Created by Grigory Entin on 08/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public extension KVOCompliantUserDefaults {
	@NSManaged public var cellHeightCachingEnabled: Bool
}

public protocol TableViewDynamicHeightCellCacheControllerDataSource {
	associatedtype Weight: Hashable
	func weightForHeightDefiningValueAtIndexPath(indexPath: NSIndexPath) -> Weight
}
public struct TableViewDynamicHeightCellCacheController<DataSource: TableViewDynamicHeightCellCacheControllerDataSource> {
	let defaults = KVOCompliantUserDefaults()
	public let dataSource: DataSource
	public let heightAgnosticCellReuseIdentifier: String
	public let reuseIdentifiersForHeightCachingCells: [String]
	var frequencyForHeightsByHeightDefiningValueWeight: [DataSource.Weight : [CGFloat : Int]] = [:]
	// MARK: -
	public func estimatedRowHeightForItemAtIndexPath(indexPath: NSIndexPath) -> CGFloat? {
		guard 0 < frequencyForHeightsByHeightDefiningValueWeight.count else {
			return nil
		}
		let weight = dataSource.weightForHeightDefiningValueAtIndexPath(indexPath)
		let frequencyForHeights = frequencyForHeightsByHeightDefiningValueWeight[weight] ?? [:]
		let heightAndMaximumFrequency = frequencyForHeights.reduce((0, 0)) {$0.1 > $1.1 ? $0 : $1}
		guard 0 < heightAndMaximumFrequency.1 else {
			return nil
		}
		return heightAndMaximumFrequency.0
	}
	var reusedHeights: [CGFloat] = []
	var reusedHeightsSet: Set<CGFloat> = []
	public func reuseIdentifierForCellForRowAtIndexPath(indexPath: NSIndexPath) -> String {
		guard let estimatedHeight = estimatedRowHeightForItemAtIndexPath(indexPath) else {
			return heightAgnosticCellReuseIdentifier
		}
		guard let indexInTopReused = reusedHeights.prefix(reuseIdentifiersForHeightCachingCells.count).indexOf(estimatedHeight) else {
			return heightAgnosticCellReuseIdentifier
		}
		return reuseIdentifiersForHeightCachingCells[indexInTopReused]
	}
	public mutating func trackHeightForTableView(tableView: UITableView, displayedCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		let weight = dataSource.weightForHeightDefiningValueAtIndexPath(indexPath)
		var frequencyForHeights = frequencyForHeightsByHeightDefiningValueWeight[weight] ?? [:]
		let height = tableView.rectForRowAtIndexPath(indexPath).height
		frequencyForHeights[height] = (frequencyForHeights[height] ?? 0) + 1
		if !reusedHeightsSet.contains(height) {
			reusedHeightsSet.insert(height)
			reusedHeights += [height]
		}
		frequencyForHeightsByHeightDefiningValueWeight[weight] = frequencyForHeights
	}
	public init(dataSource: DataSource, heightAgnosticCellReuseIdentifier: String, reuseIdentifiersForHeightCachingCells: [String]) {
		self.dataSource = dataSource
		self.heightAgnosticCellReuseIdentifier = heightAgnosticCellReuseIdentifier
		self.reuseIdentifiersForHeightCachingCells = reuseIdentifiersForHeightCachingCells
	}
}