//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import RSSReaderAppConfig
import RSSReaderData
import Loggy
import GETracing
import UIKit

class AppDelegate: AppDelegateBase {
	lazy var mainScene: AnyObject = { MainScene(window: self.window!) }()
	//
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
		$(self)
		return true
	}
	override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		defer { launchingScope.leave() }
		var scope = Activity("Finishing Launching").enter(); defer { scope.leave() }
		guard nil == managedObjectContextError else {
			$(managedObjectContextError)
			presentErrorMessage(NSLocalizedString("Something went wrong.", comment: ""))
			return false
		}
		_ = mainScene
		_ = rssSession
		return true
	}
	// MARK: -
	override init() {
		super.init()
		configureAppearance()
	}
}
