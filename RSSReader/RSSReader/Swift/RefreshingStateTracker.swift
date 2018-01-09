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
	
	@objc class var keyPathsForValuesAffectingRefreshState$: Set<String> {
		return [
			#keyPath(rssSession.authenticationState$),
			#keyPath(foldersController.foldersUpdateState)
		]
	}
	
	@objc dynamic var refreshState$ : UnusedKVOValue {
		return nil
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
		guard let rssSession = rssSession else {
			return .unknown
		}
		switch rssSession.authenticationState {
		case .nonStarted:
			return .unknown
		case .inProgress:
			return .authenticating
		case .failed(let error):
			return .failedToAuthenticate(due: error)
		case .succeeded:
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
	
	public func bind() -> Handler {
		let binding = self.observe(\.refreshState$, options: .initial) { [unowned self] (_, change) in
			assert(Thread.isMainThread)
			•(change)
			self.track(.refreshing(self.refreshState))
		}
		return {
			_ = binding
		}
	}
	
	init(presentInfoMessage: @escaping (String) -> ()) {
		self.presentInfoMessage = presentInfoMessage
		super.init()
	}
	
}
