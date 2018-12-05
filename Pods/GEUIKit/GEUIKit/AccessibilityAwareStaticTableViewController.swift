//
//  AccessibilityAwareStaticTableViewController.swift
//  GEUIKit
//
//  Created by Grigory Entin on 01.12.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit.UITableViewController

open class AccessibilityAwareStaticTableViewController : UITableViewController {
	
	override open func viewDidLoad() {
		
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = 44
		tableView.rowHeight = UITableViewAutomaticDimension
		
		var cellsAndTexts: [(UITableViewCell, String?, String?)] = []
		
		let notificationCenter = NotificationCenter.default
		
		do {
			let observer = notificationCenter.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { [weak self] _ in
				
				guard let tableView = self?.tableView else {
					return
				}
				
				cellsAndTexts = tableView.visibleCells.map { ($0, $0.textLabel?.text, $0.detailTextLabel?.text) }
				x$(cellsAndTexts)
			}
			scheduledForDeinit.append {
				notificationCenter.removeObserver(observer)
			}
		}
		
		do {
			let observer = notificationCenter.addObserver(forName: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil, queue: nil) { _ in
				
				for cellAndText in cellsAndTexts {
					let (cell, text, detailText) = cellAndText
					cell.textLabel?.text = text
					cell.detailTextLabel?.text = detailText
				}
			}
			scheduledForDeinit.append {
				notificationCenter.removeObserver(observer)
			}
		}
	}
	
	var scheduledForDeinit = ScheduledHandlers()
	deinit {
		scheduledForDeinit.perform()
	}
}
