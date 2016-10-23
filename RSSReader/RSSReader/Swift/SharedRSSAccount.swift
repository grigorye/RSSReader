//
//  SharedRSSAccountConfig.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEFoundation
import GETracing
import PromiseKit
import UIKit
import Foundation

class SharedRSSAccount : NSObject {
	var session: RSSSession?
	var loginAndPassword: LoginAndPassword!
	lazy var loginAndPasswordBinding: AnyObject = {
		let update = {
			self.loginAndPassword = $(defaults.loginAndPassword)
			guard let loginAndPassword = self.loginAndPassword, loginAndPassword.isValid() else {
				self.session = nil
				return
			}
			self.session = RSSSession(loginAndPassword: loginAndPassword)
		}
		update()
		return NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object:nil, queue:nil) { [unowned self] notification in
			if defaults.loginAndPassword != self.loginAndPassword {
				update()
			}
		}
	}()
	enum AuthenticationState {
		case Unknown, InProgress, Succeeded, Failed(error: Error)
		@objc enum RawValue : Int {
			case Unknown, InProgress, Succeeded, Failed
		}
		var rawValue: RawValue {
			switch self {
			case .Unknown:
				return .Unknown
			case .InProgress:
				return .InProgress
			case .Succeeded:
				return .Succeeded
			case .Failed(error: _):
				return .Failed
			}
		}
	}
	var authenticationState: AuthenticationState = .Unknown {
		didSet {
			self.authenticationStateRawValue = self.authenticationState.rawValue
		}
	}
	dynamic var authenticationStateRawValue: AuthenticationState.RawValue = .Unknown
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
			self.authenticationState = .InProgress
			return rssSession.authenticate()
		}.recover { authenticationError -> Void in
			self.authenticationState = .Failed(error: authenticationError)
			throw $(authenticationError)
		}.then {
			self.authenticationState = .Succeeded
		}
	}

}
