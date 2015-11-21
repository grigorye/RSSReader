//
//  LoginAndPassword.swift
//  RSSReader
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

public struct LoginAndPassword {
	public let login: String?
	public let password: String?
	public func isValid() -> Bool {
		return (login != nil) && (password != nil)
	}
	public init(login: String?, password: String?) {
		self.login = login
		self.password = password
	}
}

func == (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
	return (left.login == right.login) && (left.password == right.password)
}
func != (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
	return !(left == right)
}
