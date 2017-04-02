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
import UIKit

class AppDelegate : AppDelegateBase {
	lazy var mainScene: AnyObject = { MainScene(window: self.window!) }()
	//
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
		$(self)
		return true
	}
	func loadPersistentStoresInteractively(completion: @escaping (Error?) -> ()) {
		var scope = Activity("Loading Persistent Stores").enter()
		loadPersistentStores { error in
			guard let loadPersistentStoresError = error else {
				scope.leave()
				return
			}
			trackError($(loadPersistentStoresError))
			DispatchQueue.main.async {
				$(loadPersistentStoresError)
				self.loadPersistentStoresAfterRemovalInteractively(completion: completion)
				scope.leave()
			}
		}
	}
	func loadPersistentStoresAfterRemovalInteractively(completion: @escaping (Error?) -> ()) {
		do {
			var scope = Activity("Erasing persistent stores as part of recovery").enter(); defer { scope.leave() }
			try erasePersistentStores()
		} catch {
			completion(error)
			return
		}
		var scope = Activity("Loading persistent stores after erasing").enter()
		loadPersistentStores { error in
			DispatchQueue.main.async {
				defer { scope.leave() }
				guard let loadPersistentStoresError = error else {
					presentErrorMessage(NSLocalizedString("Something went wrong. Offline data has been erased.", comment: ""))
					return
				}
				$(loadPersistentStoresError)
				presentErrorMessage(NSLocalizedString("Something went wrong. Offline data might be unavailable. Please re-install the application to avoid further problems.", comment: ""))
			}
		}
	}
	// MARK: -
	override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		defer { launchingScope.leave() }
		var scope = Activity("Finishing Launching").enter(); defer { scope.leave() }
		guard super.application(application, didFinishLaunchingWithOptions: launchOptions) else {
			return false
		}
		do {
			loadPersistentStoresInteractively { error in
				_ = $(error)
			}
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
