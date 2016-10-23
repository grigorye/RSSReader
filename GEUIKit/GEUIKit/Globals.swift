//
//  Globals.swift
//  GEBase
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import UIKit
import Foundation

public let urlTaskGeneratorProgressBinding: AnyObject = {
	let taskGenerator = progressEnabledURLSessionTaskGenerator
	return KVOBinding(taskGenerator•#keyPath(ProgressEnabledURLSessionTaskGenerator.progresses), options: []) { change in
		let networkActivityIndicatorShouldBeVisible = 0 < taskGenerator.progresses.count
		UIApplication.shared.isNetworkActivityIndicatorVisible = (networkActivityIndicatorShouldBeVisible)
	}
}()
