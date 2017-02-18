//
//  HomeViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 24/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

func configureItemsViewControllerForFavorites(_ itemsViewController: ItemsViewController) {
	itemsViewController.title = NSLocalizedString("Favorites", comment: "")
	if let favoritesFolder = Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
		itemsViewController.container = favoritesFolder
	}
	itemsViewController.showUnreadEnabled = false
	itemsViewController.multipleSourcesEnabled = true
}

class HomeViewController: UITableViewController {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch $(segue.identifier!) {
		case R.segue.homeViewController.showHistory.identifier:
			()
		case R.segue.homeViewController.showSubscriptions.identifier:
			let foldersViewController = segue.destination as! FoldersViewController
			if let rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
				foldersViewController.rootFolder = rootFolder
			}
		case R.segue.homeViewController.showFavorites.identifier:
			let itemsViewController = segue.destination as! ItemsViewController
			configureItemsViewControllerForFavorites(itemsViewController)
		default:
			()
		}
	}
}
