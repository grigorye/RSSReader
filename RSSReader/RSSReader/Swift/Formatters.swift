//
//  Formatters.swift
//  RSSReader
//
//  Created by Grigory Entin on 05.01.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

/// - Tag: Shared-Formatters

let dateComponentsFormatter = DateComponentsFormatter() … {
	$0.unitsStyle = .abbreviated
	$0.allowsFractionalUnits = true
	$0.maximumUnitCount = 1
	$0.allowedUnits = [.minute, .year, .month, .weekOfMonth, .day, .hour]
}

let loadAgoDateComponentsFormatter = DateComponentsFormatter() … {
	$0.unitsStyle = .full
	$0.allowsFractionalUnits = true
	$0.maximumUnitCount = 1
	$0.allowedUnits = [.minute, .year, .month, .weekOfMonth, .day, .hour]
}

let loadAgoLongDateComponentsFormatter = DateComponentsFormatter() … {
	$0.unitsStyle = .full
	$0.allowsFractionalUnits = true
	$0.maximumUnitCount = 1
	$0.includesApproximationPhrase = true
	$0.allowedUnits = [.minute, .year, .month, .weekOfMonth, .day, .hour]
}
