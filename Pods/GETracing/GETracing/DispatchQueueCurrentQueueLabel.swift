//
//  DispatchQueueCurrentQueueLabel.swift
//  GETracing
//
//  Created by Grigory Entin on 06/04/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Dispatch

extension DispatchQueue {
	
	/// Returns label suitable for logging.
	public class var currentQueueLabel: String? {
		let ptr = __dispatch_queue_get_label(nil)
		return String(validatingUTF8: ptr)
	}
}
