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

/// This is an attempt to speed up scrolling by avoiding re-layouting of table view cells where height depends on a single parameter (typically height of a single subview), utilizing different cells for different heights.
public struct TableViewHeightBasedReusedCellGenerator<DataSource: TableViewHeightBasedReusedCellGeneratorDataSource> {
	public unowned let dataSource: DataSource
	
	/// Cell reuse identifier used as a fallback when the height information is not available.
	public let heightAgnosticCellReuseIdentifier: String

	public let reuseIdentifiersForHeightCachingCells: [String]
	
	// MARK: -
	
	/// Cached known heights as an array
	var reusedHeights: [CGFloat] = []
	/// Known heights as a set
	var reusedHeightsSet: Set<CGFloat> = []
	/// Map of known heights to cell hegihts
	var variableHeightsForHeight: [CGFloat : CGFloat] = [:]
	
	/// Returns cell reuse identifier based on the variable height computed for index path.
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
		guard !reusedHeightsSet.contains(height) else {
			return
		}
		reusedHeightsSet.insert(height)
		reusedHeights += [height]
		let variableHeight = dataSource.variableHeight(forCell: cell)
		variableHeightsForHeight[height] = variableHeight
		(cell as! SystemLayoutSizeCachingTableViewCell).reused = true
	}
	public init(dataSource: DataSource, heightAgnosticCellReuseIdentifier: String, reuseIdentifiersForHeightCachingCells: [String]) {
		self.dataSource = dataSource
		self.heightAgnosticCellReuseIdentifier = heightAgnosticCellReuseIdentifier
		self.reuseIdentifiersForHeightCachingCells = reuseIdentifiersForHeightCachingCells
	}
}

#endif
