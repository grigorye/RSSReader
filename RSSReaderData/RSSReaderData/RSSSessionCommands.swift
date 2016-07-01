//
//  RSSSessionCommands.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData
import Foundation

protocol PersistentDataUpdateCommand {
	var URLRequestRelativeString: String { get }
	func preprocessed(_ error: ErrorProtocol) -> ErrorProtocol
	func validate(data: Data) throws
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws
}

extension PersistentDataUpdateCommand {
	func preprocessed(_ error: ErrorProtocol) -> ErrorProtocol {
		return error
	}
	func validate(data: Data) throws {
	}
}

// MARK: -

struct UpdateSubscriptions : PersistentDataUpdateCommand {
	let URLRequestRelativeString = "/reader/api/0/subscription/list"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		let subscriptions = try importedSubscriptionsFromJsonData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(subscriptions)
	}
}

struct UpdateUserInfo : PersistentDataUpdateCommand {
	let URLRequestRelativeString = "/reader/api/0/user-info"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		let readFolder = try readFolderImportedFromUserInfoData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(readFolder)
	}
}

struct UpdateUnreadCounts : PersistentDataUpdateCommand {
	let URLRequestRelativeString = "/reader/api/0/unread-count"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		let containers = try containersImportedFromUnreadCountsData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(containers)
	}
}

struct PullTags : PersistentDataUpdateCommand {
	let URLRequestRelativeString = "/reader/api/0/tag/list"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		try! data.write(to: lastTagsFileURL, options: .dataWritingAtomic)
		let tags = try tagsImportedFromJsonData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(tags)
	}
}

struct UpdateStreamPreferences : PersistentDataUpdateCommand {
	let URLRequestRelativeString = "/reader/api/0/preference/stream/list"
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
		try! data.write(to: lastTagsFileURL, options: .dataWritingAtomic)
		let streamPreferences: () = try streamPreferencesImportedFromJsonData(data, managedObjectContext: backgroundQueueManagedObjectContext)
		•(streamPreferences)
	}
}

struct MarkAllAsRead : PersistentDataUpdateCommand {
	let container: Container
	func validate(data: Data) throws {
		guard let body = String(data: data, encoding: String.Encoding.utf8) else {
			throw RSSSessionError.badResponseDataForMarkAsRead(data: data)
		}
		guard body == "OK" else {
			throw RSSSessionError.unexpectedResponseTextForMarkAsRead(body: body as String)
		}
	}
	var URLRequestRelativeString: String {
		let containerIDPercentEncoded = self.container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics())!
		let newestItemTimestampUsec = self.container.newestItemDate.timestampUsec
		return "/reader/api/0/mark-all-as-read?s=\(containerIDPercentEncoded)&ts=\(newestItemTimestampUsec)"
	}
	func importResult(_ data: Data, into managedObjectContext: NSManagedObjectContext) throws {
	}
}
