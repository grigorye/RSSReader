//
//  RSSContainerTableViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 15/05/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation

class ContainerTableViewController: UITableViewController {
	var container: Container!
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionHeaderView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("SectionHeader") as! ContainerTableViewSectionHeaderView
		sectionHeaderView.titleLabel.text = (self.container as! Titled).visibleTitle
		return sectionHeaderView
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.registerNib(UINib(nibName: "ContainerTableViewSectionHeader", bundle: self.nibBundle), forHeaderFooterViewReuseIdentifier: "SectionHeader")
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 10
	}
}
