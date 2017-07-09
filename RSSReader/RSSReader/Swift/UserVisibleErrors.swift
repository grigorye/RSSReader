//
//  UserVisibleErrors.swift
//  RSSReader
//
//  Created by Grigory Entin on 30.06.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import RSSReaderAppConfig
import Foundation

extension ItemSummaryWebViewController {
	
	private func presentErrorMessage(_ text: String, underlyingError error: Error? = nil) {
		RSSReaderAppConfig.presentErrorMessage(text, underlyingError: error)
	}
	
}
extension ItemSummaryWebViewController {
	
	enum UserVisibleError {
		case unableToExpand(due: Error)
		case unableToLoadSummary(due: Error)
	}
	
	func track(_ error: UserVisibleError) {
		switch x$(error) {
		case .unableToExpand(due: let error):
			presentErrorMessage(NSLocalizedString("Unable to expand", comment: ""), underlyingError:  error)
		case .unableToLoadSummary(due: let error):
			presentErrorMessage(NSLocalizedString("Unable to load summary", comment: ""), underlyingError:  error)
		}
	}
	
}

extension ItemsViewController {
	
	enum UserVisibleError {
		case failedToLoadMore(due: Error?)
	}
	
	func track(_ error: UserVisibleError) {
		switch x$(error) {
		case .failedToLoadMore(due: let error):
			presentErrorMessage(NSLocalizedString("Failed to load more.", comment: ""), underlyingError: error)
		}
	}
	
}
