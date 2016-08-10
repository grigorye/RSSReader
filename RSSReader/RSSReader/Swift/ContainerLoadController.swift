//
//  ContainerLoadController.swift
//  RSSReader
//
//  Created by Grigory Entin on 09/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import PromiseKit
import CoreData
import Foundation

class ContainerLoadController {
	dynamic var container: Container!
	dynamic var unreadOnly = false
	class var keyPathsForValuesAffectingContainerViewState: Set<String> {
		return [
			#keyPath(container.viewStates),
			#keyPath(containerViewPredicate)
		]
	}
	var containerViewStateRetained: RSSReaderData.ContainerViewState?
	dynamic var containerViewState: RSSReaderData.ContainerViewState? {
		let containerViewState = (container!.viewStates.filter { $0.containerViewPredicate.isEqual(containerViewPredicate) }).onlyElement
		self.containerViewStateRetained = containerViewState
		return $(containerViewState)
	}
	private var ongoingLoadDate: Date?
	private var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState?.continuation }
	}
	class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [#keyPath(containerViewState.loadDate)]
	}
	private dynamic var loadDate: Date! {
		set { containerViewState!.loadDate = newValue! }
		get { return containerViewState?.loadDate }
	}
	private var lastLoadedItem: Item? {
		return containerViewState?.lastLoadedItem
	}
	private var loadCompleted: Bool {
		set { containerViewState!.loadCompleted = newValue }
		get { return containerViewState?.loadCompleted ?? false }
	}
	private var loadError: ErrorProtocol? {
		set { containerViewState!.loadError = newValue }
		get { return containerViewState?.loadError }
	}
	//
	private var loadInProgress = false
	private var nowDate: Date!
	//
	class var keyPathsForValuesAffectingContainerViewPredicate: Set<String> {
		return [#keyPath(unreadOnly)]
	}
	@objc private var containerViewPredicate: Predicate {
		if unreadOnly {
			return Predicate(format: "SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return Predicate(value: true)
		}
	}
	//
	func loadMore(_ completionHandler: (ErrorProtocol?) -> Void) {
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
		let excludedCategory: Folder? = unreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: mainQueueManagedObjectContext) : nil
		let numberOfItemsToLoad = 500
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
				return (NSEntityDescription.insertNewObject(forEntityName: "ContainerViewState", into: managedObjectContext) as! RSSReaderData.ContainerViewState) … {
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
			if nil == continuation {
				self.loadCompleted = true
			}
		}.always { () -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			self.loadInProgress = false
		}.then {
			completionHandler(nil)
		}.error { error -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			completionHandler(error)
		}
	}
}
