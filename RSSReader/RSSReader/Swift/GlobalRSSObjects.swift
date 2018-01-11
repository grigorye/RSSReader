//
//  GlobalRSSObjects.swift
//  RSSReader
//
//  Created by Grigory Entin on 05.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import RSSReaderData
import Foundation.NSObject

private let globalFoldersController = GlobalFoldersController()

extension NSObject {
	@objc var foldersController: GlobalFoldersController {
		return globalFoldersController
	}
}

private var rssSessionBinding = DefaultRSSSessionBinding()

extension NSObject {
	
	@objc var rssSession: RSSSession? {
		return RSSReader.rssSession
	}
}

var rssSession: RSSSession? {
	
	return rssSessionBinding.session
}
