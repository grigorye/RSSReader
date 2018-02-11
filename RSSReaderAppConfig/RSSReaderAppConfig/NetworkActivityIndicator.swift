//
//  NetworkActivityIndicator.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 11.02.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import UIKit
import FTLinearActivityIndicator

let networkActivityIndicatorInitializer: Void = {
	
	UIApplication.configureLinearNetworkActivityIndicatorIfNeeded()
}()
