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

public protocol TableViewHeightBasedReusedCellGeneratorDataSource : class {
	func variableHeightForCell(cell: UITableViewCell) -> CGFloat
	func isReadyForMeasuringHeigthsForData() -> Bool
	func variableHeightForDataAtIndexPath(indexPath: NSIndexPath) -> CGFloat
}

public struct TableViewHeightBasedReusedCellGenerator<DataSource: TableViewHeightBasedReusedCellGeneratorDataSource> {
	public unowned let dataSource: DataSource
	public let heightAgnosticCellReuseIdentifier: String
	public let reuseIdentifiersForHeightCachingCells: [String]
	// MARK: -
	var reusedHeights: [CGFloat] = []
	var reusedHeightsSet: Set<CGFloat> = []
	var variableHeightsForHeight: [CGFloat : CGFloat] = [:]
	public func reuseIdentifierForCellForRowAtIndexPath(indexPath: NSIndexPath) -> String {
		guard dataSource.isReadyForMeasuringHeigthsForData() else {
			return heightAgnosticCellReuseIdentifier
		}
		let variableHeight = dataSource.variableHeightForDataAtIndexPath(indexPath)
		let heightX: CGFloat? = {
			for (heightI, variableHeightI) in variableHeightsForHeight {
				if variableHeightI == variableHeight {
					return heightI
				}
			}
			return nil
		}()
		guard let height = heightX else {
			return heightAgnosticCellReuseIdentifier
		}
		guard let indexInTopReused = reusedHeights.prefix(reuseIdentifiersForHeightCachingCells.count).indexOf(height) else {
			return heightAgnosticCellReuseIdentifier
		}
		return reuseIdentifiersForHeightCachingCells[indexInTopReused]
	}
	public mutating func addRowHeight(height: CGFloat, forCell cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		if !reusedHeightsSet.contains(height) {
			reusedHeightsSet.insert(height)
			reusedHeights += [height]
			variableHeightsForHeight[height] = dataSource.variableHeightForCell(cell)
			(cell as! SystemLayoutSizeCachingTableViewCell).reused = true
		}
	}
	public init(dataSource: DataSource, heightAgnosticCellReuseIdentifier: String, reuseIdentifiersForHeightCachingCells: [String]) {
		self.dataSource = dataSource
		self.heightAgnosticCellReuseIdentifier = heightAgnosticCellReuseIdentifier
		self.reuseIdentifiersForHeightCachingCells = reuseIdentifiersForHeightCachingCells
	}
}