//
//  CoreDataAwareErrorDescription.swift
//  GECoreData
//
//  Created by Grigory Entin on 11.03.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import CoreData
import Foundation

private let standardUserInfoErrorKeys = [
	NSLocalizedDescriptionKey,
	NSLocalizedFailureErrorKey,
	NSLocalizedFailureReasonErrorKey,
	NSLocalizedRecoveryOptionsErrorKey,
	NSLocalizedRecoverySuggestionErrorKey
]

public func coreDataAwareDescription(of error: Error) -> String {
	let nserror = error as NSError
	let dumpedUserInfoKeys: [String] = [
		NSDetailedErrorsKey,
		NSPersistentStoreSaveConflictsErrorKey
	]
	let (dumpedUserInfo, dumpedUserInfoEntries): ([String : Any], [String : Any]) = {
		let userInfo = nserror.userInfo
		let dumpedUserInfoEntries = userInfo.filter {(key, _) in dumpedUserInfoKeys.contains(key)}
		let dumpedUserInfo = userInfo.filter {(key, _) in !dumpedUserInfoKeys.contains(key)}
		return (dumpedUserInfo, dumpedUserInfoEntries)
	}()
	
	let dumpedUserInfoEntriesDescription = dumpedUserInfoEntries.map({ (key, value) in
		let x = value as! [Any]
		return "\(key): \(x)"
	}).joined(separator: " ")
	
	let standardUserInfo = dumpedUserInfo.filter {(key, _) in standardUserInfoErrorKeys.contains(key)}
	let customUserInfo = dumpedUserInfo.filter {(key, _) in !standardUserInfoErrorKeys.contains(key)}
	
	let standardError = NSError(domain: nserror.domain, code: nserror.code, userInfo: standardUserInfo)
	let customUserInfoDescription: String = "CustomUserInfo: \(customUserInfo)"
	
	return ["\(standardError)", customUserInfoDescription, dumpedUserInfoEntriesDescription].flatMap {$0}.joined(separator: " ")
}
