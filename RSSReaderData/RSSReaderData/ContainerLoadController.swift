//
//  ContainerLoadController.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 09/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import PromiseKit
import CoreData
import Foundation

public class ContainerLoadController : NSObject {
	let session: RSSSession
	@objc let container: Container
	let unreadOnly: Bool
	public var numberOfItemsToLoadLater = 100
	public var numberOfItemsToLoadInitially = 500
	
	// MARK: -
	
	@objc dynamic var containerViewState: ContainerViewState?
	func bindContainerViewState() -> Handler {
		let binding = self.observe(\.container.viewStates, options: [.initial]) { [unowned self] (_, _) in
			self.containerViewState = self.container.viewStates.filter {
				$0.containerViewPredicate == self.containerViewPredicate
			}.onlyElement
		}
		return { _ = binding }
	}

	// MARK: -
	
	public func bind() {
		scheduledForUnbind += [self.bindContainerViewState()]
	}
	var scheduledForUnbind = ScheduledHandlers()
	public func unbind() {
		scheduledForUnbind.perform()
	}

	// MARK: -
	
	var continuation: String? {
		set { containerViewState!.continuation = newValue }
		get { return containerViewState?.continuation }
	}
	@objc class var keyPathsForValuesAffectingLoadDate: Set<String> {
		return [#keyPath(containerViewState.loadDate)]
	}
	@objc private (set) public dynamic var loadDate: Date! {
		set { x$(containerViewState!).loadDate = newValue! }
		get { return x$(containerViewState)?.loadDate }
	}
	public var lastLoadedItemDate: Date? {
		set { containerViewState!.lastLoadedItemDate = newValue }
		get { return containerViewState?.lastLoadedItemDate }
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
	private lazy var containerViewPredicate: NSPredicate = {
		if self.unreadOnly {
			return NSPredicate(format: "SUBQUERY(\(#keyPath(Item.categoryItems.category)), $x, $x.\(#keyPath(Folder.streamID)) ENDSWITH %@).@count == 0", argumentArray: [readTagSuffix])
		}
		else {
			return NSPredicate(value: true)
		}
	}()
	// MARK: -
	public var refreshing: Bool {
		return loadInProgress && (nil == continuation)
	}
	public func reset() {
		precondition(!loadInProgress)
		self.continuation = nil
		self.loadCompleted = false
		self.lastLoadedItemDate = nil
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
		let context = container.managedObjectContext!
		let excludedCategory: Folder? = unreadOnly ? x$(Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: context)) : nil
		let numberOfItemsToLoad = (oldContinuation != nil) ? numberOfItemsToLoadLater : numberOfItemsToLoadInitially
		let containerViewStateObjectID = typedObjectID(for: containerViewState)
		let containerObjectID = typedObjectID(for: container)!
		let containerViewPredicate = self.containerViewPredicate
		let session = self.session
		firstly { () -> Promise<()> in
			guard !session.authenticated else {
				return Promise(value: ())
			}
			return session.authenticate()
		}.then { (_) -> Promise<StreamContents.ResultType> in
			return Promise { fulfill, reject in
				context.perform {
					session.streamContents(self.container, excludedCategory: excludedCategory, continuation: oldContinuation, count: numberOfItemsToLoad, loadDate: x$(oldOngoingLoadDate)).then(on: zalgo) { streamContentsResult -> () in
						fulfill(streamContentsResult)
					}.catch { error in
						reject(error)
					}
				}
			}
		}.then(on: zalgo) { streamContentsResult -> String? in
			let ongoingLoadDate = x$(self.ongoingLoadDate)
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
			let (existingItems, newItems) = streamContentsResult.1.items
			let items = existingItems + newItems
			let lastLoadedItem = items.last
			let continuation = streamContentsResult.1.continuation
			containerViewState … {
				$0.continuation = continuation
				$0.lastLoadedItemDate = lastLoadedItem?.date
			}
			if let lastLoadedItem = lastLoadedItem {
				assert(containerViewPredicate.evaluate(with: lastLoadedItem))
			}
			x$(managedObjectContext.insertedObjects.map { $0.objectID });
			x$(managedObjectContext.updatedObjects.map { $0.objectID });
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
		}.then { (_) in
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
	deinit {
		x$(self)
	}
}
