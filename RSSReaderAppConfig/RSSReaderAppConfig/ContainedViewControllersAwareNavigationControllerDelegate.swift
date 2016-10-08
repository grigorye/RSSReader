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
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		•(self)
		viewController.makeContainedViewControllersPerformBlock { containedViewController in
			containedViewController.viewDidAppearInNavigationController(navigationController, animated: animated)
		}
	}
}

extension UIViewController {
	func makeContainedViewControllersPerformBlock(_ block: (UIViewController) -> ()) {
		block(self)
		for viewController in self.childViewControllers {
			viewController.makeContainedViewControllersPerformBlock(block)
		}
	}
}

extension UIViewController {
	func viewDidAppearInNavigationController(_ navigationController: UINavigationController, animated: Bool) {
	}
}
