//
//  SystemLayoutSizeCachingTableViewCell.swift
//  GEBase
//
//  Created by Grigory Entin on 08/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit.UITableViewCell

struct TargetSizeAndLayoutSizeDefiningValue {
	let targetSize: CGSize
	let layoutSizeDefiningValue: NSObject
}

extension TargetSizeAndLayoutSizeDefiningValue : Hashable, Equatable {
	var hashValue: Int {
		return "\(targetSize)".hash &+ layoutSizeDefiningValue.hashValue
	}
}
func == (lhs: TargetSizeAndLayoutSizeDefiningValue, rhs: TargetSizeAndLayoutSizeDefiningValue) -> Bool {
	guard lhs.targetSize == rhs.targetSize else {
		return false
	}
	guard lhs.layoutSizeDefiningValue == rhs.layoutSizeDefiningValue else {
		return false
	}
	return true
}

public class SystemLayoutSizeCachingTableViewCellDataSource {
	let layoutSizeDefiningValueForCell: (UITableViewCell) -> NSObject?
	let cellShouldBeReusedWithoutLayout: (UITableViewCell) -> Bool
	var cachedSystemLayoutSizes: [TargetSizeAndLayoutSizeDefiningValue : CGSize] = [:]
	public init(layoutSizeDefiningValueForCell: @escaping (UITableViewCell) -> NSObject?, cellShouldBeReusedWithoutLayout: @escaping (UITableViewCell) -> Bool) {
		self.layoutSizeDefiningValueForCell = layoutSizeDefiningValueForCell
		self.cellShouldBeReusedWithoutLayout = cellShouldBeReusedWithoutLayout
	}
}

public extension TypedUserDefaults {
	@NSManaged public var cellSystemLayoutSizeCachingEnabled: Bool
}

open class SystemLayoutSizeCachingTableViewCell: UITableViewCell {
	var reused = false
	public var systemLayoutSizeCachingDataSource: SystemLayoutSizeCachingTableViewCellDataSource?
	open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
		guard defaults.cellSystemLayoutSizeCachingEnabled else {
			return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		}
		guard let systemLayoutSizeCachingDataSource = systemLayoutSizeCachingDataSource, let layoutSizeDefiningValue = systemLayoutSizeCachingDataSource.layoutSizeDefiningValueForCell(self) else {
			return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		}
		let cacheKey = TargetSizeAndLayoutSizeDefiningValue(targetSize: targetSize, layoutSizeDefiningValue: layoutSizeDefiningValue)
		if let cachedSystemLayoutSize = systemLayoutSizeCachingDataSource.cachedSystemLayoutSizes[cacheKey] {
			return cachedSystemLayoutSize
		}
		let systemLayoutSize = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
		systemLayoutSizeCachingDataSource.cachedSystemLayoutSizes[cacheKey] = systemLayoutSize
		return systemLayoutSize
	}
	open override func prepareForReuse() {
		guard defaults.cellSystemLayoutSizeCachingEnabled else {
			super.prepareForReuse()
			return
		}
		super.prepareForReuse()
		reused = true
	}
	var layoutSubviewsInvocationsCount = 0
	open override func layoutSubviews() {
		layoutSubviewsInvocationsCount += 1
		let dt = disableTrace(); defer { _ = dt }
		x$(layoutSubviewsInvocationsCount)
		guard let systemLayoutSizeCachingDataSource = systemLayoutSizeCachingDataSource else {
			super.layoutSubviews()
			return
		}
		guard defaults.cellSystemLayoutSizeCachingEnabled else {
			super.layoutSubviews()
			return
		}
		guard reused && systemLayoutSizeCachingDataSource.cellShouldBeReusedWithoutLayout(self) else {
			super.layoutSubviews()
			return
		}
		self.translatesAutoresizingMaskIntoConstraints = true
	}
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: x$(reuseIdentifier))
	}
	required public init?(coder aDecoder: NSCoder) {
		let dt = disableTrace(); defer { _ = dt }
		super.init(coder: aDecoder)
		x$(reuseIdentifier!)
	}
}

#endif
