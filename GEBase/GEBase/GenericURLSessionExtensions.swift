//
//  GenericURLSessionExtensions.swift
//  GEBase
//
//  Created by Grigory Entin on 14.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

extension URLSession {
	func progressEnabledDataTask(with request: URLRequest, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)?) -> URLSessionDataTask? {
		let progress = Progress(totalUnitCount: 1)
		return self.dataTask(with: $(request)) { data, response, error in
			progress.becomeCurrent(withPendingUnitCount: 1)
			progress.resignCurrent()
			completionHandler?(data, $(response), error)
		}
	}
}
