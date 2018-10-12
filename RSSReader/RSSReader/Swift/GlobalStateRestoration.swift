//
//  GlobalStateRestoration.swift
//  RSSReader
//
//  Created by Grigory Entin on 15.10.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import JGProgressHUD
import Loggy
import UIKit

extension TypedUserDefaults {
	@NSManaged var stateRestorationEnabled: Bool
	@NSManaged var stateRestorationIndicatorEnabled: Bool
}

private let currentRestorationFormatVersion: Int32 = 2

private let stateRestorationHud = JGProgressHUD(style: .light) … {
	
	$0.textLabel.text = "State Restored"
	$0.indicatorView = JGProgressHUDSuccessIndicatorView()
}

private var scheduledForDidDecodeRestorableState = ScheduledHandlers()

extension AppDelegate {
	private enum Restorable: String {
		case restorationFormatVersion
	}
	func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		x$(self)
		coder.encode(currentRestorationFormatVersion, forKey: Restorable.restorationFormatVersion.rawValue)
		return true
	}
	
	func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		
		Activity(named: "State Restoration").execute { done in
			scheduledForDidDecodeRestorableState.append {
				done()
			}
		}

		x$(self)
		
		let restorationFormatVersion = coder.decodeInt32(forKey: Restorable.restorationFormatVersion.rawValue)
		if x$(restorationFormatVersion) < currentRestorationFormatVersion {
			return false
		}
		
		let stateRestorationEnabled = x$(defaults.stateRestorationEnabled)

		if stateRestorationEnabled, defaults.stateRestorationIndicatorEnabled {
			
			scheduledForDidDecodeRestorableState.append {
				DispatchQueue.main.async {
					stateRestorationHud.show(in: UIApplication.shared.keyWindow!)
					stateRestorationHud.dismiss(afterDelay: 1)
				}
			}
		}
		
		return stateRestorationEnabled
	}
	
	func application(_ application: UIApplication, didDecodeRestorableStateWith coder: NSCoder) {
		
		scheduledForDidDecodeRestorableState.perform()
	}
}
