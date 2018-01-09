//
//  DefaultRSSSessionBinding.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation

/// As long as it exists, keeps the session up-to-date with the value in defaults.
class DefaultRSSSessionBinding : NSObject {
	
	private (set) var session: RSSSession?
	
	private var loginAndPassword: LoginAndPassword! {
		
		didSet {
			if loginAndPassword != oldValue {
				updateSessionForLoginAndPassword()
			}
		}
	}
	
	private func updateSessionForLoginAndPassword() {
		
		guard let loginAndPassword = self.loginAndPassword, loginAndPassword.isValid() else {
			self.session = nil
			return
		}
		self.session = RSSSession(loginAndPassword: loginAndPassword)
	}
	
	private func updateLoginAndPassword() {
		
		self.loginAndPassword = defaults.loginAndPassword
	}
	
	/// The binding to the externally set login and password (imp: in defaults).
	private lazy var loginAndPasswordBinding: AnyObject = {
		
		updateLoginAndPassword()
		
		return NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [unowned self] _ in

			self.updateLoginAndPassword()
		}
	}()
	
	override init() {
		
		super.init()
		_ = loginAndPasswordBinding
	}
}
