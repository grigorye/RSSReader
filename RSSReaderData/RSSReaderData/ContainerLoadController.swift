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

public class LoadInProgress : NSObject {
	
	/// Acts like the session identifier, in cases when load is obsoletted by another load. Load date of the first chunk.
	let loadDate: Date
	
	let promise: Promise<Void>
	let reject: (Error) -> Void
	
	init(loadDate: Date, promise: Promise<Void>, reject: @escaping (Error) -> Void) {
		self.loadDate = loadDate
		self.promise = promise
		self.reject = reject
		super.init()
	}
}

///
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
	
	public var loadInProgress: LoadInProgress?
	
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
		set { x$(containerViewState!).loadDate = x$(newValue!) }
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
	#if false
	public var refreshing: Bool {
		guard nil != loadInProgress else {
			return false
		}
		return (nil == continuation)
	}
	#endif

	public func clear() {
		self.continuation = nil
		self.loadCompleted = false
		self.lastLoadedItemDate = nil
		self.loadError = nil
	}
	
	private var excludedCategory: Folder? {
		return unreadOnly ? x$(Folder.folderWithTagSuffix(readTagSuffix, managedObjectContext: context)) : nil
	}
	
	private var context: NSManagedObjectContext {
		return container.managedObjectContext!
	}
	
	private var numberOfItemsToLoad: Int {
		if continuation != nil {
			return numberOfItemsToLoadLater
		} else {
			return numberOfItemsToLoadInitially
		}
	}
	
	// MARK: -

	/// Schedules asynchronous load of next portion of the data, returning cancellation closure. Should not be invoked without cancelling any loads in progress.
	public func loadMore(_ completionHandler: @escaping (Error?) -> Void) -> () -> Void {
		
		assert(Thread.isMainThread)
		assert(nil == self.loadInProgress)
		assert(!loadCompleted)
		assert(nil == loadError)
		
		let continuation = self.continuation
		
		let loadDate: Date = {
			guard nil != continuation else {
				return Date()
			}
			return self.loadDate
		}()
		
		let (promise, _, reject) = Promise<Void>.pending()
		let loadInProgress = LoadInProgress(loadDate: loadDate, promise: promise, reject: reject)
		
		let containerViewStateObjectID = typedObjectID(for: containerViewState)
		let containerObjectID = typedObjectID(for: container)!
		
		let session = self.session
		let containerViewPredicate = self.containerViewPredicate
		let context = self.context
		let excludedCategory = self.excludedCategory
		let numberOfItemsToLoad = self.numberOfItemsToLoad
		
		let chainPromise = firstly { () -> Promise<()> in
			
			guard !x$(session.authenticated) else {
				return Promise(value: ())
			}
			
			return x$(session.authenticate())
			
		}.then { (_) -> Promise<StreamContents.ResultType> in
			
			return Promise { fulfill, reject in
				
				x$(fulfill)
				
				context.perform {
					
					let streamContents = session.streamContents(self.container, excludedCategory: excludedCategory, continuation: continuation, count: numberOfItemsToLoad, loadDate: x$(loadInProgress.loadDate))
					
					streamContents.then(on: zalgo) { streamContentsResult -> () in
						
						x$(fulfill(streamContentsResult))
						
					}.catch { error in
						
						x$(reject(error))
					}
				}
			}
			
		}.then(on: zalgo) { streamContentsResult -> String? in
			
			guard loadInProgress.loadDate == x$(self.loadInProgress?.loadDate) else {
				
				/// Bail out if the load is no longer current
				throw NSError.cancelledError()
			}
			
			let managedObjectContext = streamContentsResult.0
			let containerViewState = containerViewStateObjectID?.object(in: managedObjectContext) ?? {
				
				return ContainerViewState(context: managedObjectContext) … {
					let container = containerObjectID.object(in: managedObjectContext)
					$0.container = container
					$0.containerViewPredicate = containerViewPredicate
				}
			}()
			
			if nil == continuation {
				// Make it new load date if the load of first chunk succeeded.
				self.loadDate = loadInProgress.loadDate
			}
			else {
				assert(self.loadDate == loadInProgress.loadDate)
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
			
			if nil == x$(continuation) {
				self.loadCompleted = true
			}
			
		}.always { () -> Void in
			
			guard loadInProgress.loadDate == x$(self.loadInProgress?.loadDate) else {
				return
			}
			
			self.loadInProgress = nil
			
		}.then { (_) in
			
			x$(completionHandler(nil))
			
		}.catch { error -> Void in
			
			x$(error)
			
			guard loadInProgress.loadDate == x$(self.loadInProgress?.loadDate) else {
				
				// Ignore errors from no longer current load.
				return
			}
			
			completionHandler(error)
		}
		
		_ = when(resolved: loadInProgress.promise, chainPromise).value
		
		return {
			loadInProgress.reject(x$(NSError.cancelledError()))
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
