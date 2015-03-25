//
//  HomeViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 24/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

class HomeViewController: UITableViewController {
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch trace("segue.identifier", segue.identifier!) {
		case MainStoryboard.SegueIdentifiers.ShowHistory:
			()
		case MainStoryboard.SegueIdentifiers.ShowSubscriptions:
			let foldersViewController = segue.destinationViewController as! FoldersListTableViewController
			if let rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: self.mainQueueManagedObjectContext) {
				foldersViewController.rootFolder = rootFolder
			}
		case MainStoryboard.SegueIdentifiers.ShowFavorites:
			let itemsListViewController = segue.destinationViewController as! ItemsListViewController
			if let favoritesFolder = Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: self.mainQueueManagedObjectContext) {
				itemsListViewController.container = favoritesFolder
			}
		default:
			abort()
		}
	}
}