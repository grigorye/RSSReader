//
//  GlobalStateRestoration.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEFoundation
import GEBase
import Loggy
import UIKit

extension KVOCompliantUserDefaults {
	@NSManaged var stateRestorationEnabled: Bool
}

private var activity = Activity("State Restoration")
var activityScope: Activity.Scope!

private let currentRestorationFormatVersion: Int32 = 1

extension AppDelegate {
	private enum Restorable: String {
		case restorationFormatVersion
	}
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		$(self)
		coder.encode(currentRestorationFormatVersion, forKey: Restorable.restorationFormatVersion.rawValue)
		return true
	}
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		activityScope = activity.enter()
		$(self)
		let restorationFormatVersion = coder.decodeInt32(forKey: Restorable.restorationFormatVersion.rawValue)
		if $(restorationFormatVersion) < currentRestorationFormatVersion {
			return false
		}
		return $(defaults.stateRestorationEnabled)
	}
	func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
		activityScope.leave()
	}
}
