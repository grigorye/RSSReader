//
//  MainNavigationController.swift
//  RSSReader
//
//  Created by Grigory Entin on 26.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class MainNavigationController : UINavigationController {
	@IBOutlet var extraLeftBarButtonItem: UIBarButtonItem!
	override func viewDidLoad() {
		let firstViewController = self.viewControllers.first! as! UIViewController
		firstViewController.navigationItem.leftBarButtonItems = [extraLeftBarButtonItem] + (firstViewController.navigationItem.leftBarButtonItems ?? [])
	}
}
