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

func configureFavoritesItemListViewController(_ itemListViewController: ItemListViewController) {
	itemListViewController.title = NSLocalizedString("Favorites", comment: "")
	if let favoritesFolder = Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
		itemListViewController.container = favoritesFolder
	}
	itemListViewController.showUnreadEnabled = false
	itemListViewController.multipleSourcesEnabled = true
}

class HomeViewController: UITableViewController {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch $(segue.identifier!) {
		case MainStoryboard.SegueIdentifiers.ShowHistory:
			()
		case MainStoryboard.SegueIdentifiers.ShowSubscriptions:
			let foldersViewController = segue.destination as! FolderListTableViewController
			if let rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
				foldersViewController.rootFolder = rootFolder
			}
		case MainStoryboard.SegueIdentifiers.ShowFavorites:
			let itemListViewController = segue.destination as! ItemListViewController
			configureFavoritesItemListViewController(itemListViewController)
		default:
			()
		}
	}
}
