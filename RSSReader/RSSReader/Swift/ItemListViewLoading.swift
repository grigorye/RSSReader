//
//  ItemListViewLoading.swift
//  RSSReader
//
//  Created by Grigory Entin on 25/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import PromiseKit
import CoreData
import Foundation

extension ItemsListViewController {
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if nil != rssSession && nil != view.superview && !refreshControl!.isRefreshing {
			loadMoreIfNecessary()
		}
	}
}
extension ItemsListViewController {
	private var numberOfItemsToLoadPastVisible: Int {
		return defaults.numberOfItemsToLoadPastVisible
	}
	private var numberOfItemsToLoadInitially: Int {
		return defaults.numberOfItemsToLoadInitially
	}
	private var numberOfItemsToLoadLater: Int {
		return defaults.numberOfItemsToLoadLater
	}
	// MARK: -
	private class var keyPathsForValuesAffectingContainerViewState: Set<String> {
		return [
			#keyPath(container.viewStates),
			#keyPath(containerViewPredicate)
		]
	}
	private dynamic var containerViewState: ContainerViewState? {
		let containerViewState = (container!.viewStates.filter { $0.containerViewPredicate.isEqual(containerViewPredicate) }).onlyElement
		self.containerViewStateRetained = containerViewState
		return (containerViewState)
	}
	var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState?.continuation }
	}
	private class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [#keyPath(containerViewState.loadDate)]
	}
	dynamic var loadDate: Date? {
		set { containerViewState!.loadDate = newValue! }
		get { return containerViewState?.loadDate }
	}
	private var lastLoadedItem: Item? {
		return containerViewState?.lastLoadedItem
	}
	var loadCompleted: Bool {
		set { containerViewState!.loadCompleted = newValue }
		get { return containerViewState?.loadCompleted ?? false }
	}
	var loadError: Error? {
		set { containerViewState!.loadError = newValue }
		get { return containerViewState?.loadError }
	}
	// MARK: -
	func loadMore(_ completionHandler: (Bool) -> Void) {
		assert(!loadInProgress)
		assert(!loadCompleted)
		assert(nil == loadError)
		let oldContinuation = self.continuation
		if nil == oldContinuation {
			ongoingLoadDate = Date()
		}
		else if nil == ongoingLoadDate {
			ongoingLoadDate = loadDate
		}
		let oldOngoingLoadDate = ongoingLoadDate!
		loadInProgress = true
		let excludedCategory: Folder? = showUnreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext) : nil
		let numberOfItemsToLoad = (oldContinuation != nil) ? numberOfItemsToLoadLater : numberOfItemsToLoadInitially
		let containerViewStateObjectID = typedObjectID(for: containerViewState)
		let containerObjectID = typedObjectID(for: container)!
		let containerViewPredicate = self.containerViewPredicate
		firstly {
			rssSession!.streamContents(container!, excludedCategory: excludedCategory, continuation: oldContinuation, count: numberOfItemsToLoad, loadDate: $(oldOngoingLoadDate))
		}.then(on: zalgo) { streamContentsResult -> String? in
			let ongoingLoadDate = $(self.ongoingLoadDate)
			guard oldOngoingLoadDate == ongoingLoadDate else {
				throw NSError.cancelledError()
			}
			let managedObjectContext = streamContentsResult.0
			let containerViewState = containerViewStateObjectID?.object(in: managedObjectContext) ?? {
				return (NSEntityDescription.insertNewObject(forEntityName: "ContainerViewState", into: managedObjectContext) as! ContainerViewState) … {
					let container = containerObjectID.object(in: managedObjectContext)
					$0.container = container
					$0.containerViewPredicate = containerViewPredicate
				}
			}()
			if nil == oldContinuation {
				containerViewState.loadDate = ongoingLoadDate
			}
			else {
				assert(containerViewState.loadDate == ongoingLoadDate)
			}
			let items = streamContentsResult.1.items
			let lastLoadedItem = items.last
			let continuation = streamContentsResult.1.continuation
			containerViewState … {
				$0.continuation = continuation
				$0.lastLoadedItem = lastLoadedItem
			}
			if let lastLoadedItem = lastLoadedItem {
				assert(containerViewPredicate.evaluate(with: lastLoadedItem))
			}
			try managedObjectContext.save()
			return continuation
		}.then { continuation -> Void in
			if let lastLoadedItem = self.lastLoadedItem {
				assert(nil != self.dataSource.indexPath(forObject: lastLoadedItem))
			}
			if nil == continuation {
				self.loadCompleted = true
				UIView.animate(withDuration: 0.4) {
					self.tableView.tableFooterView = nil
				}
			}
		}.always { () -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			self.loadInProgress = false
			self.loadMoreIfNecessary()
		}.catch { error -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			self.presentErrorMessage(
				String.localizedStringWithFormat(
					"%@ %@",
					NSLocalizedString("Failed to load more.", comment: ""),
					(error as NSError).localizedDescription
				)
			)
		}
	}
	private func shouldLoadMore(for lastLoadedItemDate: Date?) -> Bool {
		guard !(loadInProgress || loadCompleted || loadError != nil) else {
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
		let barrierRow = min(lastVisibleIndexPath.row + numberOfItemsToLoadPastVisible, numberOfRows - 1)
		let barrierIndexPath = IndexPath(item: barrierRow, section: lastVisibleIndexPath.section)
		let barrierItem = dataSource.object(at: barrierIndexPath)
		return !(((lastLoadedItemDate).compare((barrierItem.date))) == .orderedAscending)
	}
	private func loadMoreIfNecessary(for lastLoadedItemDate: Date?) {
		guard shouldLoadMore(for: lastLoadedItemDate) else {
			if (loadCompleted) {
				tableView.tableFooterView = nil
			}
			return
		}
		loadMore { _ in
		}
	}
	func loadMoreIfNecessary() {
		self.loadMoreIfNecessary(for: self.lastLoadedItem?.date)
	}
}
