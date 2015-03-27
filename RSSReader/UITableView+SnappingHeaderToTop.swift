//
//  UITableView+SnappingHeaderToTop.swift
//  RSSReader
//
//  Created by Grigory Entin on 03/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit.UITableView

extension UITableView {
	func snapHeaderToTop(#animated: Bool) {
		if let tableHeaderView = tableHeaderView {
			let insetAwareTableHeaderViewFrame = CGRectOffset(tableHeaderView.frame, 0, -contentInset.top)
			if contentOffset.y < CGRectGetMaxY(insetAwareTableHeaderViewFrame) {
				let adjustedContentOffsetY = (contentOffset.y < CGRectGetMidY(insetAwareTableHeaderViewFrame) ? CGRectGetMinY : CGRectGetMaxY)(insetAwareTableHeaderViewFrame);
				setContentOffset(CGPoint(x: contentOffset.x, y: adjustedContentOffsetY), animated: animated)
			}
		}
	}
}