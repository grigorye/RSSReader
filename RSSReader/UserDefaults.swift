//
//  UserDefaults.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension NSUserDefaults {
	func authTokenDefault() -> NSString {
		return "authToken"
	}
	var authToken: NSString? {
		get {
			return self.stringForKey(authTokenDefault())
		}
		set {
			if let authToken = newValue {
				defaults.setObject(authToken as NSString, forKey: authTokenDefault())
			}
			else {
				defaults.removeObjectForKey(authTokenDefault())
			}
		}
	}
	var loginAndPassword: LoginAndPassword {
		get {
			let login = defaults.stringForKey("login")
			let password = defaults.stringForKey("password")
			return LoginAndPassword(login: login, password: password)
		}
	}
}
