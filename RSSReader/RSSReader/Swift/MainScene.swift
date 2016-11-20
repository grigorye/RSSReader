//
//  AppDelegateViewControllers.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GECoreData
import GEFoundation
import GETracing
import UIKit

extension KVOCompliantUserDefaults {
	@NSManaged var hideBarsOnSwipe: Bool
}

class MainScene : NSObject {

	var window: UIWindow
	
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
		let $ = (self.tabBarController.viewControllers![1] as! UINavigationController).viewControllers.first as! ItemsViewController
		configureItemsViewControllerForFavorites($)
		return $
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
				let title = NSLocalizedString("Favorites", comment: "");
				return UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
			}()
		}
	}
}
