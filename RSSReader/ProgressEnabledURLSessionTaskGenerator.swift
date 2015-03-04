//
//  ProgressEnabledURLSessionTaskGenerator.swift
//  RSSReader
//
//  Created by Grigory Entin on 04/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

let URLSessionTaskGeneratorErrorDomain = "com.grigoryentin.URLSessionTaskGenerator"

enum URLSessionTaskGeneratorError: Int {
	case UnexpectedHTTPResponseStatus
}

class ProgressEnabledURLSessionTaskGenerator: NSObject {
	let dispatchQueue = dispatch_get_main_queue()
	dynamic var progresses = [NSProgress]()
	private var mutableProgresses: NSMutableArray {
		return mutableArrayValueForKey("progresses")
	}
	let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
	// MARK: -
	func dataTaskForHTTPRequest(request: NSURLRequest, completionHandler: (NSData!, NSError!) -> Void) -> NSURLSessionDataTask {
		let progress = NSProgress(totalUnitCount: 1)
		progress.becomeCurrentWithPendingUnitCount(1)
		let sessionTask = session.progressEnabledDataTaskWithRequest(request) { data, response, error in
			dispatch_async(self.dispatchQueue) {
				self.mutableProgresses.removeObjectIdenticalTo(progress)
			}
			if let error = error {
				completionHandler(nil, error)
				return
			}
			let completionError = nil != error ? error : {
				let httpResponse = response as! NSHTTPURLResponse
				if httpResponse.statusCode != 200 {
					return NSError(domain: URLSessionTaskGeneratorErrorDomain, code: URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus.rawValue, userInfo: ["httpResponse": httpResponse])
				}
				else {
					completionHandler(data, nil)
					return nil
				}
			}()
			if let error = error {
				completionHandler(nil, error)
			}
		}
		progress.resignCurrent()
		dispatch_async(self.dispatchQueue) {
			self.mutableProgresses.addObject(progress)
		}
		return sessionTask
	}
}
