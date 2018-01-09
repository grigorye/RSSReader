//
//  Globals.swift
//  RSSReader
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

let applicationDomain = Bundle.main.bundleIdentifier!

let applicationDelegate = (UIApplication.shared.delegate as! AppDelegate)

let userCachesDirectoryURL: URL = {
	let fileManager = FileManager.default
	let x = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
	return x
}()
