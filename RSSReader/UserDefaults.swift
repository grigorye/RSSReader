//
//  UserDefaults.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension KVOCompliantUserDefaults {
	var loginAndPassword: LoginAndPassword {
		get {
			let login = self.login
			let password = self.password
			return LoginAndPassword(login: login, password: password)
		}
	}
}
