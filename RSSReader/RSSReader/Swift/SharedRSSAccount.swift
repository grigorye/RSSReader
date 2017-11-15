//
//  SharedRSSAccountConfig.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import PromiseKit
import UIKit
import Foundation

class SharedRSSAccount : NSObject {
	var session: RSSSession?
	var loginAndPassword: LoginAndPassword!
	lazy var loginAndPasswordBinding: AnyObject = {
		let update = {
			self.loginAndPassword = x$(defaults.loginAndPassword)
			guard let loginAndPassword = self.loginAndPassword, loginAndPassword.isValid() else {
				self.session = nil
				return
			}
			self.session = RSSSession(loginAndPassword: loginAndPassword)
		}
		update()
		return NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [unowned self] notification in
			if defaults.loginAndPassword != self.loginAndPassword {
				update()
			}
		}
	}()
	enum AuthenticationState {
		case unknown, inProgress, succeeded, failed(error: Error)
		@objc enum RawValue : Int {
			case unknown, inProgress, succeeded, failed
		}
		var rawValue: RawValue {
			switch self {
			case .unknown:
				return .unknown
			case .inProgress:
				return .inProgress
			case .succeeded:
				return .succeeded
			case .failed(error: _):
				return .failed
			}
		}
	}
	var authenticationState: AuthenticationState = .unknown {
		didSet {
			self.authenticationStateRawValue = self.authenticationState.rawValue
		}
	}
	@objc dynamic var authenticationStateRawValue: AuthenticationState.RawValue = .unknown
	override init() {
		super.init()
		_ = loginAndPasswordBinding
	}
}

extension SharedRSSAccount {

	func authenticate() -> Promise<Void> {
		let rssSession = rssAccount.session!
		return firstly {
			guard !rssSession.authenticated else {
				return Promise(value: ())
			}
			self.authenticationState = .inProgress
			return rssSession.authenticate()
		}.recover { authenticationError -> Void in
			self.authenticationState = .failed(error: authenticationError)
			throw x$(authenticationError)
		}.then { _ in
			self.authenticationState = .succeeded
		}
	}

}
