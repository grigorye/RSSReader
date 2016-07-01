//
//  ProgressEnabledURLSessionTaskGenerator.swift
//  GEBase
//
//  Created by Grigory Entin on 04/03/15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

public enum URLSessionTaskGeneratorError: ErrorProtocol {
	case UnexpectedHTTPResponseStatus(httpResponse: HTTPURLResponse)
}

public class ProgressEnabledURLSessionTaskGenerator: NSObject {
	let dispatchQueue = DispatchQueue.main
	public dynamic var progresses = [Progress]()
	private var mutableProgresses: NSMutableArray {
		return mutableArrayValue(forKey: "progresses")
	}
	let session = URLSession(configuration: URLSessionConfiguration.default())
	// MARK: -
	public typealias HTTPDataTaskCompletionHandler = (Data?, HTTPURLResponse?, ErrorProtocol?) -> Void
	public func dataTask(for request: URLRequest, completionHandler: HTTPDataTaskCompletionHandler) -> URLSessionDataTask {
		let progress = Progress(totalUnitCount: 1)
		progress.becomeCurrent(withPendingUnitCount: 1)
		•(request)
		•(request.allHTTPHeaderFields)
		let sessionTask = session.progressEnabledDataTask(with: request) { data, response, error in
			self.dispatchQueue.async {
				self.mutableProgresses.removeObject(identicalTo: progress)
			}
			let httpResponse = response as! HTTPURLResponse?
			do {
				guard nil == error else {
					throw error!
				}
				let httpResponse = httpResponse!
				guard httpResponse.statusCode == 200 else {
					throw URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus(httpResponse: httpResponse)
				}
				completionHandler(data, httpResponse, nil)
			} catch {
				completionHandler(nil, httpResponse, error)
			}
		}
		progress.resignCurrent()
		self.dispatchQueue.async {
			self.mutableProgresses.add(progress)
		}
		return sessionTask
	}
	public typealias TextTaskCompletionHandler = (String?, ErrorProtocol?) -> Void
	public func textTask(for request: URLRequest, completionHandler: TextTaskCompletionHandler) -> URLSessionDataTask? {
		enum Error: ErrorProtocol {
			case DataDoesNotMatchTextEncoding(data: Data, encoding: String.Encoding)
		}
		return dataTask(for: request) { data, httpResponse, error in
			do {
				if let error = error {
					throw error
				}
				let httpResponse = httpResponse!
				let encoding: String.Encoding = {
					if let textEncodingName = httpResponse.textEncodingName {
						return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(textEncodingName)))
					}
					else {
						return String.Encoding.utf8
					}
				}()
				let data = data!
				guard let text = String(data: data, encoding: encoding) else {
					throw Error.DataDoesNotMatchTextEncoding(data: data, encoding: encoding)
				}
				completionHandler(text, nil)
			} catch {
				completionHandler(nil, $(error))
			}
		}
	}
}
