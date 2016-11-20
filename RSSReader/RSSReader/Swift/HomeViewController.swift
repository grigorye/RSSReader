//
//  HomeViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 24/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GETracing
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
		case MainStoryboard.SegueIdentifiers.ShowHistory:
			()
		case MainStoryboard.SegueIdentifiers.ShowSubscriptions:
			let foldersViewController = segue.destination as! FoldersViewController
			if let rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
				foldersViewController.rootFolder = rootFolder
			}
		case MainStoryboard.SegueIdentifiers.ShowFavorites:
			let itemsViewController = segue.destination as! ItemsViewController
			configureItemsViewControllerForFavorites(itemsViewController)
		default:
			()
		}
	}
}
