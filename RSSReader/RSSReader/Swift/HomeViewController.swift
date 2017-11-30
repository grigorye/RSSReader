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
		
		var cellsAndTexts: [(UITableViewCell, String?, String?)] = []
		
		let notificationCenter = NotificationCenter.default
		
		do {
			let observer = notificationCenter.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { [weak self] _ in
				
				guard let tableView = self?.tableView else {
					return
				}
				
				cellsAndTexts = tableView.visibleCells.map { ($0, $0.textLabel?.text, $0.detailTextLabel?.text) }
				x$(cellsAndTexts)
			}
			scheduledForDeinit.append {
				notificationCenter.removeObserver(observer)
			}
		}

		do {
			let observer = notificationCenter.addObserver(forName: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil, queue: nil) { _ in
				
				for cellAndText in cellsAndTexts {
					let (cell, text, detailText) = cellAndText
					cell.textLabel?.text = text
					cell.detailTextLabel?.text = detailText
				}
			}
			scheduledForDeinit.append {
				notificationCenter.removeObserver(observer)
			}
		}
	}

	var scheduledForDeinit = ScheduledHandlers()
	deinit {
		scheduledForDeinit.perform()
	}
}
