//
//  Globals.swift
//  GEBase
//
//  Created by Grigory Entin on 18.07.15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import UIKit
import Foundation

public let urlTaskGeneratorProgressBinding: AnyObject = {
	let taskGenerator = progressEnabledURLSessionTaskGenerator
	return taskGenerator.observe(\.progresses) { (_, _) in
		let networkActivityIndicatorShouldBeVisible = 0 < taskGenerator.progresses.count
		UIApplication.shared.isNetworkActivityIndicatorVisible = (networkActivityIndicatorShouldBeVisible)
	}
}()
