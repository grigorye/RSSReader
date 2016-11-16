//
//  ItemListViewLoading.swift
//  RSSReader
//
//  Created by Grigory Entin on 25/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEFoundation
import GETracing
import PromiseKit
import CoreData
import Foundation

extension KVOCompliantUserDefaults {
	@NSManaged var numberOfItemsToLoadPastVisible: Int
	@NSManaged var numberOfItemsToLoadInitially: Int
	@NSManaged var numberOfItemsToLoadLater: Int
}

extension ItemListViewController {
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if nil != rssSession && nil != view.superview && !refreshControl!.isRefreshing {
			loadMoreIfNecessary()
		}
	}
}
extension ItemListViewController {
	func loadMore(_ completionHandler: @escaping () -> Void) {
		let loadController = self.loadController!
		loadController.loadMore { [weak loadController] error in
			completionHandler()
			guard nil == error else {
				let error = error!
				self.presentErrorMessage(
					String.localizedStringWithFormat(
						"%@ %@",
						NSLocalizedString("Failed to load more.", comment: ""),
						(error as NSError).localizedDescription
					)
				)
				return
			}
			guard let loadController = loadController else {
				return
			}
			if let lastLoadedItem = loadController.lastLoadedItem {
				assert(nil != self.dataSource.indexPath(forObject: lastLoadedItem))
			}
			guard !loadController.loadCompleted else {
				UIView.animate(withDuration: 0.4) {
					self.tableView.tableFooterView = nil
				}
				return
			}
			DispatchQueue.main.async { [weak self] in
				self?.loadMoreIfNecessary()
			}
		}
	}
	private func shouldLoadMore(for lastLoadedItemDate: Date?) -> Bool {
		guard !(loadController.loadInProgress || loadController.loadCompleted || loadController.loadError != nil) else {
			return false
		}
		guard let lastLoadedItemDate = lastLoadedItemDate else {
			return true
		}
		guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else {
			return false
		}
		guard 0 < indexPathsForVisibleRows.count else {
			return true
		}
		let lastVisibleIndexPath = indexPathsForVisibleRows.last!
		let numberOfRows = dataSource.numberOfObjects(inSection: 0)
		assert(0 < numberOfRows)
		let barrierRow = min(lastVisibleIndexPath.row + defaults.numberOfItemsToLoadPastVisible, numberOfRows - 1)
		let barrierIndexPath = IndexPath(item: barrierRow, section: lastVisibleIndexPath.section)
		let barrierItem = dataSource.object(at: barrierIndexPath)
		return !(((lastLoadedItemDate).compare((barrierItem.date))) == .orderedAscending)
	}
	private func loadMoreIfNecessary(for lastLoadedItemDate: Date?) {
		guard $(shouldLoadMore(for: $(lastLoadedItemDate))) else {
			if (loadController.loadCompleted) {
				tableView.tableFooterView = nil
			}
			return
		}
		loadMore {}
	}
	func loadMoreIfNecessary() {
		self.loadMoreIfNecessary(for: loadController.lastLoadedItem?.date)
	}
}
