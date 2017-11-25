//
//  HistoryViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.02.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation

class HistoryViewController : ItemsViewController {

	typealias _Self = HistoryViewController
	private var nowDate: Date!
	
	override lazy var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: #keyPath(Item.lastOpenedDate), ascending: false)]
	override lazy var predicate: NSPredicate = NSPredicate(format: "\(#keyPath(Item.lastOpenedDate)) != nil", argumentArray: [])
	override lazy var canLoadItems: Bool = false
	
	// MARK: -
	override func viewWillAppear(_ animated: Bool) {
		nowDate = Date()
		super.viewWillAppear(animated)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		showsContainerTitle = false
	}
	
	// MARK: -
	deinit {
		x$(self)
	}
}
