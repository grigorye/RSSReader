//
//  LoginAndPassword.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

public struct LoginAndPassword {
	public let login: String?
	public let password: String?
	public func isValid() -> Bool {
		return (login?.lengthOfBytes(using: .utf8) != 0) && (password?.lengthOfBytes(using: .utf8) != 0)
	}
	public init(login: String?, password: String?) {
		self.login = login
		self.password = password
	}
}
extension LoginAndPassword : Equatable {}

public func == (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
	return (left.login == right.login) && (left.password == right.password)
}
