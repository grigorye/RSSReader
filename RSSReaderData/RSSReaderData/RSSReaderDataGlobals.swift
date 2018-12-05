//
//  RSSReaderDataGlobals.swift
//  RSSReader
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension UserDefaults {
	var login: String! {
		return self.string(forKey: "login")
	}
	var password: String! {
		return self.string(forKey: "password")
	}
	var loginAndPassword: LoginAndPassword {
		get {
			let login = self.login
			let password = self.password
			return LoginAndPassword(login: login, password: password)
		}
	}
	var itemsAreSortedByLoadDate: Bool {
		return self.bool(forKey: "itemsAreSortedByLoadDate")
	}
	var authToken: String? {
		get {
			return self.string(forKey: "authToken")
		}
		set {
			if let authToken = newValue {
				self.set(authToken, forKey: "authToken")
			}
			else {
				self.removeObject(forKey: "authToken")
			}
		}
	}
}
