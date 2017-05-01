//
//  ItemTableViewDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 25/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import UIKit

var estimateCount = 0

extension TypedUserDefaults {

	@NSManaged var prototypeBasedCellHeightEnabled: Bool

}

extension ItemsViewController {
#if false
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		let dt = disableTrace(); defer { _ = dt }
		$(indexPath)
		estimateCount += 1
		return 44
#if false
		guard !defaults.fixedHeightItemRowsEnabled else {
			return 44
		}
		guard let rowHeightEstimator = dataSource.rowHeightEstimator else {
			return UITableViewAutomaticDimension
		}
		guard let estimatedHeight = rowHeightEstimator.estimatedRowHeightForItemAtIndexPath(indexPath) else {
			return UITableViewAutomaticDimension
		}
		return estimatedHeight
#endif
	}
#endif
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		guard defaults.prototypeBasedCellHeightEnabled else {
			return UITableViewAutomaticDimension
		}
		let dt = disableTrace(); defer { _ = dt }
		$(indexPath)
		let dataSource = tableView.dataSource as! ItemTableViewDataSource
		let item = dataSource.object(at: indexPath)
		prototypeCell.setData((item: item, container: dataSource.container, nowDate: Date()))
		let systemLayoutSize = prototypeCell.systemLayoutSizeFitting(tableView.bounds.size)
		return systemLayoutSize.height
	}
	
	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard defaults.frequencyAndWeightBasedTableRowHeightEstimatorEnabled else {
			return
		}
		guard !defaults.fixedHeightItemRowsEnabled else {
			return
		}
		let rowHeight = tableView.rectForRow(at: indexPath).height
		dataSource.addRowHeight(rowHeight, for: cell)
	}
	
}
