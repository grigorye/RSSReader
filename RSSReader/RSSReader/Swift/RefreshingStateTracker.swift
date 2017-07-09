//
//  RefreshingStateTracker.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.07.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation

class RefreshingStateTracker: NSObject {
	
	internal var presentInfoMessage: (String) -> ()
	
	@objc class var keyPathsForValuesAffectingRefreshStateD: Set<String> {
		return [
			#keyPath(rssAccount.authenticationStateRawValue),
			#keyPath(foldersController.foldersUpdateState)
		]
	}
	
	@objc dynamic var refreshStateD: NSObject {
		assert(false)
	}
	
	enum RefreshState {
		case unknown
		case authenticating
		case failedToAuthenticate(due: Error)
		case failed(due: Error)
		case inProgress(with: FoldersUpdateState)
		case completed(at: Date)
	}
	
	var refreshState: RefreshState {
		switch rssAccount.authenticationStateRawValue {
		case .Unknown:
			return .unknown
		case .InProgress:
			return .authenticating
		case .Failed:
			guard case .Failed(let error) = rssAccount.authenticationState else {
				fatalError()
			}
			return .failedToAuthenticate(due: error)
		case .Succeeded:
			let foldersUpdateState = foldersController.foldersUpdateState
			switch foldersUpdateState {
			case .ended:
				let foldersController = self.foldersController
				if let foldersUpdateError = foldersController.foldersLastUpdateError {
					return .failed(due: foldersUpdateError)
				}
				let foldersLastUpdateDate = foldersController.foldersLastUpdateDate!
				return .completed(at: foldersLastUpdateDate)
			default:
				return .inProgress(with: foldersUpdateState)
			}
		}
	}
	
	func bindTrackRefreshState() -> Handler {
		let binding = self.observe(\.refreshStateD, options: .initial) { [unowned self] (_, change) in
			assert(Thread.isMainThread)
			•(change)
			self.track(.refreshing(self.refreshState))
		}
		return {
			_ = binding
		}
	}
	
	var refreshStateTrackingBinding: Handler!
	
	deinit {
		x$(self)
	}
	
	init(presentInfoMessage: @escaping (String) -> ()) {
		self.presentInfoMessage = presentInfoMessage
		super.init()
		refreshStateTrackingBinding = bindTrackRefreshState()
	}
	
}
