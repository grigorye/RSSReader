//
//  RSSSessionTaskGeneration.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import Foundation

public protocol RSSSessionDataTaskGenerator {

	typealias DataTaskCompletionHandler = (Data?, HTTPURLResponse?, Error?) -> Void

	func dataTask(for request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask
	
}

extension RSSSession {
	
	typealias TaskCompletionHandler = RSSSessionDataTaskGenerator.DataTaskCompletionHandler
	
	// MARK: -
	func dataTask(with request: URLRequest, completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask {
		return dataTaskGenerator.dataTask(for: request, completionHandler: completionHandler)
	}
	
	func authenticatedDataTask(with request: URLRequest, completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask {
		precondition(nil != self.authToken)
		let authenticatedRequest = request ≈ {
			$0.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			$0.addValue(self.inoreaderAppID, forHTTPHeaderField: "AppId")
			$0.addValue(self.inoreaderAppKey, forHTTPHeaderField: "AppKey")
		}
		return self.dataTask(with: authenticatedRequest) { data, response, error in
			if case let URLSessionTaskGeneratorError.UnexpectedHTTPResponseStatus(httpResponse)? = error, httpResponse.statusCode == 401 {
				self.authToken = nil
			}
			completionHandler(data, response, error)
		}
	}
	
}
