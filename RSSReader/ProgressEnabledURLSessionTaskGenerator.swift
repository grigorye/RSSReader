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
	typealias HTTPDataTaskCompletionHandler = (NSData!, NSHTTPURLResponse!, NSError!) -> Void
	func dataTaskForHTTPRequest(request: NSURLRequest, completionHandler: HTTPDataTaskCompletionHandler) -> NSURLSessionDataTask {
		let progress = NSProgress(totalUnitCount: 1)
		progress.becomeCurrentWithPendingUnitCount(1)
		let sessionTask = session.progressEnabledDataTaskWithRequest(request) { data, response, error in
			dispatch_async(self.dispatchQueue) {
				self.mutableProgresses.removeObjectIdenticalTo(progress)
			}
			let httpResponse = response as! NSHTTPURLResponse!
			if let error = error {
				completionHandler(nil, httpResponse, error)
				return
			}
			$(response).$()
			let completionError = nil != error ? error : {
				if httpResponse.statusCode != 200 {
					return NSError(domain: URLSessionTaskGeneratorErrorDomain, code: URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus.rawValue, userInfo: ["httpResponse": httpResponse])
				}
				else {
					completionHandler(data, httpResponse, nil)
					return nil
				}
			}()
			if let error = error {
				completionHandler(nil, httpResponse, error)
			}
		}
		progress.resignCurrent()
		dispatch_async(self.dispatchQueue) {
			self.mutableProgresses.addObject(progress)
		}
		return sessionTask
	}
	typealias TextTaskCompletionHandler = (String!, NSError!) -> Void
	func textTaskForHTTPRequest(request: NSURLRequest, completionHandler: TextTaskCompletionHandler) -> NSURLSessionDataTask {
		return dataTaskForHTTPRequest(request) { data, httpResponse, error in
			if let error = error {
				completionHandler(nil, error)
				return
			}
			let encoding: NSStringEncoding = {
				if let textEncodingName = httpResponse.textEncodingName {
					return CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(textEncodingName))
				}
				else {
					return NSUTF8StringEncoding
				}
			}()
			if let text = NSString(data: data, encoding: encoding) as String? {
				completionHandler(text, nil)
			}
			else {
				completionHandler(nil, NSError(domain: applicationErrorDomain, code: ApplicationError.DataDoesNotMatchTextEncoding.rawValue, userInfo: nil))
			}
		}
	}
}
