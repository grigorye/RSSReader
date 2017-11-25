//
//  AppDelegateViewControllers.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

extension TypedUserDefaults {
	@NSManaged var hideBarsOnSwipe: Bool
}

extension MainScene : UISplitViewControllerDelegate {

	func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
		guard x$(splitViewController.isCollapsed) else {
			return false
		}
		let masterNavigationController = splitViewController.viewControllers.first as! UINavigationController
		let secondaryNavigationController = vc as! UINavigationController
		masterNavigationController.show(secondaryNavigationController.topViewController!, sender: sender)
		return true
	}

	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		return true
	}

}

class MainScene : NSObject {

	var window: UIWindow

	lazy var splitViewController: UISplitViewController! = {
		guard let splitViewController = self.window.rootViewController! as? UISplitViewController else {
			return nil
		}
		return splitViewController … {
			$0.delegate = self
		}
	}()
	
	lazy var tabBarController: UITabBarController! = {
		return self.window.rootViewController! as? UITabBarController
	}()
	
	lazy var navigationController: UINavigationController! = {
		return self.window.rootViewController! as? UINavigationController
	}()
	
	lazy var foldersNavigationController: UINavigationController = {
		guard let tabBarController = self.tabBarController else {
			return self.navigationController
		}
		return tabBarController.viewControllers![0] as! UINavigationController
	}()
	
	lazy var foldersViewController: FoldersViewController = {
		return self.foldersNavigationController.viewControllers.first as! FoldersViewController
	}()
	
	lazy var favoritesViewController: ItemsViewController = {
		return ((self.tabBarController.viewControllers![1] as! UINavigationController).viewControllers.first as! ItemsViewController) … {
			configureForFavorites($0)
		}
	}()
	
	// MARK: -
	
	lazy var fetchedRootFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(rootTagSuffix)) { folders in
		let foldersViewController = self.foldersViewController
		foldersViewController.rootFolder = folders.last!
	}
	
	lazy var fetchedFavoritesFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(favoriteTagSuffix)) { folders in
		let foldersViewController = self.favoritesViewController
		foldersViewController.container = folders.last!
	}
	
	// MARK: -

	init(window: UIWindow) {
		self.window = window
		super.init()
		
		hideBarsOnSwipe = (nil == tabBarController) && defaults.hideBarsOnSwipe
		if nil != tabBarController {
			_ = self.fetchedRootFolderBinding
			_ = self.fetchedFavoritesFolderBinding
			foldersViewController.hidesBottomBarWhenPushed = false
			favoritesViewController.navigationItem.backBarButtonItem = {
				let title = NSLocalizedString("Favorites", comment: "")
				return UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
			}()
		}
		if let splitViewController = self.splitViewController {
			let navigationController = splitViewController.viewControllers.last as! UINavigationController
			navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
		}
	}
}
