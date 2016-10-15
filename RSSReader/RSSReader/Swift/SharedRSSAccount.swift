//
//  SharedRSSAccountConfig.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import Foundation

class SharedRSSAccount : NSObject {
	var rssSession: RSSSession?
	var loginAndPassword: LoginAndPassword!
	lazy var loginAndPasswordBinding: AnyObject = {
		let update = {
			self.loginAndPassword = $(defaults.loginAndPassword)
			guard let loginAndPassword = self.loginAndPassword, loginAndPassword.isValid() else {
				self.rssSession = nil
				openSettingsApp()
				return
			}
			self.rssSession = RSSSession(loginAndPassword: loginAndPassword)
		}
		update()
		return NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object:nil, queue:nil) { [unowned self] notification in
			if defaults.loginAndPassword != self.loginAndPassword {
				update()
			}
		}
	}()
	override init() {
		super.init()
		_ = loginAndPasswordBinding
	}
}
