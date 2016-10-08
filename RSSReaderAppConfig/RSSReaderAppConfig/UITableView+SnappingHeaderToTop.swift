//
//  UITableView+SnappingHeaderToTop.swift
//  RSSReader
//
//  Created by Grigory Entin on 03/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit.UITableView

extension UITableView {
	public func snapHeaderToTop(animated: Bool) {
		if let tableHeaderView = tableHeaderView {
			let insetAwareTableHeaderViewFrame = tableHeaderView.frame.offsetBy(dx: 0, dy: -contentInset.top)
			if contentOffset.y < insetAwareTableHeaderViewFrame.maxY {
				let adjustedContentOffsetY: CGFloat = {
					if (contentOffset.y < insetAwareTableHeaderViewFrame.midY) {
						return insetAwareTableHeaderViewFrame.minY
					}
					else {
						return insetAwareTableHeaderViewFrame.maxY
					}
				}()
				setContentOffset(CGPoint(x: contentOffset.x, y: adjustedContentOffsetY), animated: animated)
			}
		}
	}
}
