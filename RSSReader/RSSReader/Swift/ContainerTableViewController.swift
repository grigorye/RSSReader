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
	dynamic var container: Container!
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as! ContainerTableViewSectionHeaderView
		sectionHeaderView.titleLabel.text = (self.container as! Titled?)?.visibleTitle
		return sectionHeaderView
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UINib(nibName: "ContainerTableViewSectionHeader", bundle: self.nibBundle), forHeaderFooterViewReuseIdentifier: "SectionHeader")
		tableView.sectionHeaderHeight = UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight = 44
	}
}
