//
//  FrequencyAndWeightBasedTableRowHeightEstimator.swift
//  GEBase
//
//  Created by Grigory Entin on 14/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation
import UIKit

public protocol FrequencyAndWeightBasedTableRowHeightEstimatorDataSource : class {
	associatedtype Weight: Hashable
	func weightForHeightDefiningValueAtIndexPath(indexPath: NSIndexPath) -> Weight
}

public struct FrequencyAndWeightBasedTableRowHeightEstimator<DataSource: FrequencyAndWeightBasedTableRowHeightEstimatorDataSource> {
	public unowned let dataSource: DataSource
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
	public mutating func addRowHeight(height: CGFloat, forIndexPath indexPath: NSIndexPath) {
		let weight = dataSource.weightForHeightDefiningValueAtIndexPath(indexPath)
		var frequencyForHeights = frequencyForHeightsByHeightDefiningValueWeight[weight] ?? [:]
		frequencyForHeights[height] = (frequencyForHeights[height] ?? 0) + 1
		frequencyForHeightsByHeightDefiningValueWeight[weight] = frequencyForHeights
	}
	public init(dataSource: DataSource) {
		self.dataSource = dataSource
	}
}