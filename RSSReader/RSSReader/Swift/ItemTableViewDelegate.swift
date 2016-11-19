//
//  ItemTableViewDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 25/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import UIKit

extension ItemListViewController {
#if !RSS_READER_ITEM_ROW_HEIGHT_ESTIMATION_DISABLED
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
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
	}
#endif
#if false
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 44
	}
#endif
	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard !defaults.fixedHeightItemRowsEnabled else {
			return
		}
		let rowHeight = tableView.rectForRow(at: indexPath).height
		dataSource.addRowHeight(rowHeight, for: cell, at: indexPath)
	}
}
