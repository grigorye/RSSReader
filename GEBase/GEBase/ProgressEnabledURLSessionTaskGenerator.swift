//
//  ProgressEnabledURLSessionTaskGenerator.swift
//  GEBase
//
//  Created by Grigory Entin on 04/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

enum URLSessionTaskGeneratorError: ErrorType {
	case UnexpectedHTTPResponseStatus(httpResponse: NSHTTPURLResponse)
}

public class ProgressEnabledURLSessionTaskGenerator: NSObject {
	let dispatchQueue = dispatch_get_main_queue()
	public dynamic var progresses = [NSProgress]()
	private var mutableProgresses: NSMutableArray {
		return mutableArrayValueForKey("progresses")
	}
	let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
	// MARK: -
	public typealias HTTPDataTaskCompletionHandler = (NSData!, NSHTTPURLResponse!, ErrorType?) -> Void
	public func dataTaskForHTTPRequest(request: NSURLRequest, completionHandler: HTTPDataTaskCompletionHandler) -> NSURLSessionDataTask? {
		let progress = NSProgress(totalUnitCount: 1)
		progress.becomeCurrentWithPendingUnitCount(1)
		(request)
		(request.allHTTPHeaderFields)
		let sessionTask = session.progressEnabledDataTaskWithRequest(request) { data, response, error in
			dispatch_async(self.dispatchQueue) {
				self.mutableProgresses.removeObjectIdenticalTo(progress)
			}
			let httpResponse = response as! NSHTTPURLResponse!
			do {
				guard nil == error else {
					throw error
				}
				guard httpResponse.statusCode == 200 else {
					throw URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus(httpResponse: httpResponse)
				}
				completionHandler(data, httpResponse, nil)
			} catch {
				completionHandler(nil, httpResponse, error)
			}
		}
		progress.resignCurrent()
		dispatch_async(self.dispatchQueue) {
			self.mutableProgresses.addObject(progress)
		}
		return sessionTask
	}
	public typealias TextTaskCompletionHandler = (String!, ErrorType!) -> Void
	public func textTaskForHTTPRequest(request: NSURLRequest, completionHandler: TextTaskCompletionHandler) -> NSURLSessionDataTask? {
		enum Error: ErrorType {
			case DataDoesNotMatchTextEncoding(data: NSData, encoding: NSStringEncoding)
		}
		return dataTaskForHTTPRequest(request) { data, httpResponse, error in
			do {
				if let error = error {
					throw error
				}
				let encoding: NSStringEncoding = {
					if let textEncodingName = httpResponse.textEncodingName {
						return CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(textEncodingName))
					}
					else {
						return NSUTF8StringEncoding
					}
				}()
				guard let text = NSString(data: data, encoding: encoding) as String? else {
					throw Error.DataDoesNotMatchTextEncoding(data: data, encoding: encoding)
				}
				completionHandler(text, nil)
			} catch {
				completionHandler(nil, $(error))
			}
		}
	}
}
