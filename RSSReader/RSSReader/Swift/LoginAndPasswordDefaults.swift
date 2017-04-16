//
//  LoginAndPasswordDefaults.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation

extension TypedUserDefaults {
	@NSManaged var login: String!
	@NSManaged var password: String!
	//
	var loginAndPassword: LoginAndPassword {
		return LoginAndPassword(login: self.login, password: self.password)
	}
}
