//
//  RSSReaderDataGlobals.swift
//  RSSReader
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension NSUserDefaults {
	var login: String! {
		return self.stringForKey("login")
	}
	var password: String! {
		return self.stringForKey("password")
	}
	var loginAndPassword: LoginAndPassword {
		get {
			let login = self.login
			let password = self.password
			return LoginAndPassword(login: login, password: password)
		}
	}
	var itemsAreSortedByLoadDate: Bool {
		return self.boolForKey("itemsAreSortedByLoadDate")
	}
	var authToken: String? {
		get {
			return self.stringForKey("authToken")
		}
		set {
			if let authToken = newValue {
				self.setObject(authToken, forKey: "authToken")
			}
			else {
				self.removeObjectForKey("authToken")
			}
		}
	}
}
