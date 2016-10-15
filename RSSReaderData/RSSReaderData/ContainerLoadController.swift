//
//  ContainerLoadController.swift
//  RSSReader
//
//  Created by Grigory Entin on 09/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import PromiseKit
import CoreData
import Foundation

public class ContainerLoadController : NSObject {
	let session: RSSSession
	let container: Container
	let unreadOnly: Bool
	public var numberOfItemsToLoadLater = 100
	public var numberOfItemsToLoadInitially = 500
	// MARK: -
	class var keyPathsForValuesAffectingContainerViewState: Set<String> {
		return [
			#keyPath(container.viewStates),
			#keyPath(containerViewPredicate)
		]
	}
	var containerViewStateRetained: ContainerViewState?
	dynamic var containerViewState: ContainerViewState? {
		let containerViewState = (container.viewStates.filter { $0.containerViewPredicate.isEqual(containerViewPredicate) }).onlyElement
		self.containerViewStateRetained = containerViewState
		return $(containerViewState)
	}
	var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState?.continuation }
	}
	class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [#keyPath(containerViewState.loadDate)]
	}
	private (set) public dynamic var loadDate: Date! {
		set { containerViewState!.loadDate = newValue! }
		get { return containerViewState?.loadDate }
	}
	public var lastLoadedItem: Item? {
		set { containerViewState!.lastLoadedItem = newValue }
		get { return containerViewState?.lastLoadedItem }
	}
	private (set) public var loadCompleted: Bool {
		set { containerViewState!.loadCompleted = newValue }
		get { return containerViewState?.loadCompleted ?? false }
	}
	private (set) public var loadError: Error? {
		set { containerViewState!.loadError = newValue }
		get { return containerViewState?.loadError }
	}
	//
	private var ongoingLoadDate: Date?
	private (set) public var loadInProgress = false
	private var nowDate: Date!
	//
	class var keyPathsForValuesAffectingContainerViewPredicate: Set<String> {
		return [#keyPath(unreadOnly)]
	}
	@objc private var containerViewPredicate: NSPredicate {
		if unreadOnly {
			return NSPredicate(format: "SUBQUERY(\(#keyPath(Item.categories)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}
	// MARK: -
	public var refreshing: Bool {
		return loadInProgress && (nil == continuation)
	}
	public func reset() {
		precondition(!loadInProgress)
		self.continuation = nil
		self.loadCompleted = false
		self.lastLoadedItem = nil
		self.loadError = nil
	}
	// MARK: -
	public func loadMore(_ completionHandler: @escaping (Error?) -> Void) {
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
		let excludedCategory: Folder? = unreadOnly ? Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: container.managedObjectContext!) : nil
		let numberOfItemsToLoad = (oldContinuation != nil) ? numberOfItemsToLoadLater : numberOfItemsToLoadInitially
		let containerViewStateObjectID = typedObjectID(for: containerViewState)
		let containerObjectID = typedObjectID(for: container)!
		let containerViewPredicate = self.containerViewPredicate
		firstly {
			session.streamContents(container, excludedCategory: excludedCategory, continuation: oldContinuation, count: numberOfItemsToLoad, loadDate: $(oldOngoingLoadDate))
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
		}.catch { error -> Void in
			guard oldOngoingLoadDate == self.ongoingLoadDate else {
				return
			}
			completionHandler(error)
		}
	}
	public init(session: RSSSession, container: Container, unreadOnly: Bool = false) {
		self.session = session
		self.container = container
		self.unreadOnly = unreadOnly
		super.init()
	}
}