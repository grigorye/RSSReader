//
//  DebugActions.swift
//  RSSReader
//
//  Created by Grigory Entin on 01.12.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

/// Abusing segues to support debug actions.
extension UIViewController {
	
	@IBAction func unwindToForceDebugCrash(_ segue: UIStoryboardSegue) {
		
		forceDebugCrash()
	}
	
	@IBAction func unwindToTriggerDebugError(_ segue: UIStoryboardSegue) {
		
		triggerDebugError()
	}
}
