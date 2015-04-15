//
//  ApplicationErrors.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.04.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

let ApplicationErrorDomain = "com.grigoryentin.RSSReader"

enum ApplicationError: Int {
	case Unused
	case DataDoesNotMatchTextEncoding
	case UserInfoRetrievalError
	case TagsUpdateError
	case SubscriptionsUpdateError
	case UnreadCountsUpdateError
	case StreamPreferencesUpdateError
}

func applicationError(code: ApplicationError, underlyingError: NSError) -> NSError {
	return NSError(domain: ApplicationErrorDomain, code: code.rawValue, userInfo: [NSUnderlyingErrorKey: $(underlyingError).$()])
}
