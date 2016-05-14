//
//  UserDefaults.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import Foundation

extension KVOCompliantUserDefaults {
	var loginAndPassword: LoginAndPassword {
		return LoginAndPassword(login: self.login, password: self.password)
	}
}
