//
//  UserEvents.swift
//  RSSReader
//
//  Created by Grigory Entin on 30.06.17.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEAppConfig
import Foundation

extension ItemsViewController {
	
	enum UserVisibleEvent {
		case updated(at: Date)
		case notUpdatedBefore
		case markedAllAsRead
	}
	
	func track(_ event: UserVisibleEvent) {
		switch x$(event) {
		case .updated(let loadDate):
			let loadAgo = loadAgoDateComponentsFormatter.string(from: loadDate, to: Date())!
			presentInfoMessage(String.localizedStringWithFormat(NSLocalizedString("Updated %@ ago", comment: ""), loadAgo))
		case .notUpdatedBefore:
			presentInfoMessage(NSLocalizedString("Not updated before", comment: ""))
		case .markedAllAsRead:
			let message = NSLocalizedString("Marked all as read.", comment: "")
			if defaults.showMessagesInToolbar {
				presentInfoMessage(message)
			} else {
				GEAppConfig.presentInfoMessage(message)
			}
		}
	}
	
}

extension RefreshingStateTracker {
	
	enum UserVisibleEvent {
		case refreshing(RefreshingStateTracker.RefreshState)
	}
	
	func track(_ event: UserVisibleEvent) {
		switch x$(event) {
		case .refreshing(let state):
			let message: String = {
				switch state {
				case .unknown:
					return ""
				case .authenticating:
					return NSLocalizedString("Authenticating", comment: "")
				case .failedToAuthenticate(due: let error):
					return "\(error.localizedDescription)"
				case .failed(due: let error):
					return "\(error.localizedDescription)"
				case .completed(at: let date):
					let loadAgo = loadAgoDateComponentsFormatter.string(from: date, to: Date())!
					return String.localizedStringWithFormat(NSLocalizedString("Updated %@ ago", comment: ""), loadAgo)
				case .inProgress(with: let foldersUpdateState):
					return "\(foldersUpdateState)"
				}
			}()
			presentInfoMessage(message)
		}
	}
}

//
// MARK: - Presenting Messages
//

extension TypedUserDefaults {

	@NSManaged var showMessagesInToolbar: Bool
}

extension ItemsViewController {
	
	private func presentMessageInToolbar(_ text: String) {
		
		guard let statusLabel = statusLabel else {
			return
		}
		statusLabel.text = text
		statusLabel.sizeToFit()
		statusLabel.superview!.frame.size.width = statusLabel.bounds.width
		statusBarButtonItem.width = (statusLabel.superview!.bounds.width)
	}
	
	internal func presentMessage(_ text: String) {
		
		if defaults.showMessagesInToolbar {

			presentMessageInToolbar(text)
			
		} else {
			
			refreshControl?.attributedTitle = NSAttributedString(string: text)
		}
	}
	
	private func presentInfoMessage(_ text: String) {
		presentMessage(text)
	}
	
}

extension FoldersViewController {
	
	private func presentMessageInToolbar(_ text: String) {
		
		statusLabel.text = (text)
		statusLabel.sizeToFit()
		statusLabel.superview!.frame.size.width = statusLabel.bounds.width
		statusBarButtonItem.width = (statusLabel.superview!.bounds.width)
		let toolbarItems = self.toolbarItems
		self.toolbarItems = self.toolbarItems?.filter { $0 != statusBarButtonItem }
		self.toolbarItems = toolbarItems
	}
	
	private func presentMessage(_ text: String) {
		
		if defaults.showMessagesInToolbar {
			
			presentMessageInToolbar(text)
			
		} else {
			
			refreshControl?.attributedTitle = NSAttributedString(string: text)
		}
	}
	
	internal func presentInfoMessage(_ text: String) {
		presentMessage(text)
	}
}

extension FoldersViewController {
	
	enum UserVisibleEvent {
		case secondRefreshIgnored
		case refreshInitiated
		case refreshCompleted(Error?)
	}
	
	func track(_ event: UserVisibleEvent) {
		x$(event)
	}
}
