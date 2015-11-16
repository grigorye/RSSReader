//
//  HomeViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 24/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

class HomeViewController: UITableViewController {
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch $(segue.identifier!).$() {
		case MainStoryboard.SegueIdentifiers.ShowHistory:
			()
		case MainStoryboard.SegueIdentifiers.ShowSubscriptions:
			let foldersViewController = segue.destinationViewController as! FoldersListTableViewController
			if let rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
				foldersViewController.rootFolder = rootFolder
			}
		case MainStoryboard.SegueIdentifiers.ShowFavorites:
			let itemsListViewController = segue.destinationViewController as! ItemsListViewController
			itemsListViewController.title = NSLocalizedString("Favorites", comment: "")
			if let favoritesFolder = Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
				itemsListViewController.container = favoritesFolder
			}
		default:
			()
		}
	}
}