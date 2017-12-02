//
//  ItemListViewLoading.swift
//  RSSReader
//
//  Created by Grigory Entin on 25/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import PromiseKit
import CoreData
import Foundation

extension TypedUserDefaults {

	@NSManaged var numberOfItemsToLoadPastVisible: Int
	@NSManaged var numberOfItemsToLoadInitially: Int
	@NSManaged var numberOfItemsToLoadLater: Int
	@NSManaged var loadItemsUntilLast: Bool
	@NSManaged var progressIndicatorInFooterEnabled: Bool
	@NSManaged var loadOnScrollDisabled: Bool

}

extension ItemsViewController {

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard !defaults.loadOnScrollDisabled else {
			return
		}
		guard nil != rssSession else {
			return
		}
		guard nil != view.superview else {
			return
		}
		guard !canLoadItems || !refreshControl!.isRefreshing else {
			return
		}
		x$(loadMoreIfNecessary())
	}

}

protocol ItemsViewControllerLoadingImp {

	var tableFooterViewOnLoading: UIView! { get }

}

extension ItemsViewController : ItemsViewControllerLoadingImp {

	func didStartLoad() {
		guard defaults.progressIndicatorInFooterEnabled else {
			return
		}
		self.tableView.tableFooterView = self.tableFooterViewOnLoading!
	}
	
	func didCompleteLoad() {
		guard defaults.progressIndicatorInFooterEnabled else {
			return
		}
		UIView.animate(withDuration: 0.4) {
			self.tableView.tableFooterView = nil
		}
	}
	
	///
	
	func loadMore(_ completionHandler: @escaping () -> Void) -> (() -> Void)? {
		
		guard let loadController = self.loadController else {
			completionHandler()
			return nil
		}
		x$(didStartLoad())
		return loadController.loadMore { [weak loadController] error in
			completionHandler()
			if let error = error {
				self.track(.failedToLoadMore(due: error))
				return
			}
			guard let loadController = loadController else {
				return
			}
#if false
			if let lastLoadedItem = loadController.lastLoadedItem {
				assert(nil != self.dataSource.indexPath(forObject: lastLoadedItem))
			}
#endif
			guard !loadController.loadCompleted else {
				x$(self.didCompleteLoad())
				return
			}
			DispatchQueue.main.async { [weak self] in
				self?.loadMoreIfNecessary()
			}
		}
	}
	
	private func shouldLoadMore() -> Bool {
		guard let loadController = loadController else {
			return false
		}
		guard nil == loadController.loadInProgress else {
			return false
		}
		guard !(loadController.loadCompleted || loadController.loadError != nil) else {
			return false
		}
		guard let lastLoadedItemDate = loadController.lastLoadedItemDate else {
			return true
		}
		guard !defaults.loadItemsUntilLast else {
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
	
	public func loadMoreIfNecessary() {
		let dt = disableTrace(); defer { _ = dt }
		guard x$(shouldLoadMore()) else {
			return
		}
		assert(nil == loadCancellation)
		loadCancellation = loadMore {
			self.loadCancellation = nil
		}
	}
}
