//
//  GenericURLSessionExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 14.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension NSURLSession {
	func progressEnabledDataTaskWithRequest(request: NSURLRequest, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask? {
		let progress = NSProgress(totalUnitCount: 1)
		$(request.URL!).$()
		return self.dataTaskWithRequest(request) { data, response, error in
			progress.becomeCurrentWithPendingUnitCount(1)
			progress.resignCurrent()
			completionHandler?(data, response, error)
		}
	}
}
