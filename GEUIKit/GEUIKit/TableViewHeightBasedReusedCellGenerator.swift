//
//  TableViewDynamicHeightCellEstimator.swift
//  GEBase
//
//  Created by Grigory Entin on 08/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

public protocol TableViewHeightBasedReusedCellGeneratorDataSource : class {
	func variableHeight(forCell: UITableViewCell) -> CGFloat
	func isReadyForMeasuringHeigthsForData() -> Bool
	func variableHeightForDataAtIndexPath(_ indexPath: IndexPath) -> CGFloat
}

public struct TableViewHeightBasedReusedCellGenerator<DataSource: TableViewHeightBasedReusedCellGeneratorDataSource> {
	public unowned let dataSource: DataSource
	public let heightAgnosticCellReuseIdentifier: String
	public let reuseIdentifiersForHeightCachingCells: [String]
	// MARK: -
	var reusedHeights: [CGFloat] = []
	var reusedHeightsSet: Set<CGFloat> = []
	var variableHeightsForHeight: [CGFloat : CGFloat] = [:]
	public func reuseIdentifierForCellForRowAtIndexPath(_ indexPath: IndexPath) -> String {
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
		guard let indexInTopReused = reusedHeights.prefix(reuseIdentifiersForHeightCachingCells.count).index(of: height) else {
			return heightAgnosticCellReuseIdentifier
		}
		return reuseIdentifiersForHeightCachingCells[indexInTopReused]
	}
	public mutating func addRowHeight(_ height: CGFloat, forCell cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
		if !reusedHeightsSet.contains(height) {
			reusedHeightsSet.insert(height)
			reusedHeights += [height]
			variableHeightsForHeight[height] = dataSource.variableHeight(forCell: cell)
			(cell as! SystemLayoutSizeCachingTableViewCell).reused = true
		}
	}
	public init(dataSource: DataSource, heightAgnosticCellReuseIdentifier: String, reuseIdentifiersForHeightCachingCells: [String]) {
		self.dataSource = dataSource
		self.heightAgnosticCellReuseIdentifier = heightAgnosticCellReuseIdentifier
		self.reuseIdentifiersForHeightCachingCells = reuseIdentifiersForHeightCachingCells
	}
}

#endif
