//
//  HomeViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 24/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import UIKit

func configureForFavorites(_ itemsViewController: ItemsViewController) {
	
	itemsViewController … {
		
		$0.title = NSLocalizedString("Favorites", comment: "")
		
		if let favoritesFolder = Folder.folderWithTagSuffix(favoriteTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
			
			$0.container = favoritesFolder
		}
		$0.showUnreadEnabled = false
		$0.multipleSourcesEnabled = true
		$0.showsContainerTitle = false
	}
}

func configureForSubscriptions(_ foldersViewController: FoldersViewController) {
	
	foldersViewController … {
		
		$0.title = NSLocalizedString("Subscriptions", comment: "")
		
		if let rootFolder = Folder.folderWithTagSuffix(rootTagSuffix, managedObjectContext: mainQueueManagedObjectContext) {
			
			$0.rootFolder = rootFolder
		}
		$0.showsContainerTitle = false
	}
}

class HomeViewController: UITableViewController {
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		switch x$(segue.identifier!) {
			
		case R.segue.homeViewController.showHistory.identifier:
			
			()
			
		case R.segue.homeViewController.showSubscriptions.identifier:
			
			configureForSubscriptions(segue.destination as! FoldersViewController)
			
		case R.segue.homeViewController.showFavorites.identifier:
			
			configureForFavorites(segue.destination as! ItemsViewController)
			
		default:
			
			()
		}
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = 44
		tableView.rowHeight = UITableViewAutomaticDimension
	}
}
