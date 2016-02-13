//
//  ContainedViewControllersAwareNavigationControllerDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 15/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEBase
import UIKit.UINavigationController

class ContainedViewControllersAwareNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
	func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
		$(self)
		viewController.makeContainedViewControllersPerformBlock { containedViewController in
			containedViewController.viewDidAppearInNavigationController(navigationController, animated: animated)
		}
	}
}

extension UIViewController {
	func makeContainedViewControllersPerformBlock(block: (viewController: UIViewController) -> ()) {
		block(viewController: self)
		for viewController in self.childViewControllers {
			viewController.makeContainedViewControllersPerformBlock(block)
		}
	}
}

extension UIViewController {
	func viewDidAppearInNavigationController(navigationController: UINavigationController, animated: Bool) {
	}
}
