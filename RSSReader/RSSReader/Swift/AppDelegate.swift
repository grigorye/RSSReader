//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEAppConfig
import GEFoundation
import Loggy
import UIKit

class AppDelegate : GEAppConfig.AppDelegateBase {
	
	lazy var mainScene: AnyObject = { MainScene(window: self.window!) }()
	
	func loadPersistentStoresInteractively(completion: @escaping (Error?) -> ()) {
		
		Activity.label("Scheduling load of persistent stores") {
			loadPersistentStores { error in
				if let loadPersistentStoresError = error {
					trackError(x$(loadPersistentStoresError))
					
					DispatchQueue.main.async {
						x$(loadPersistentStoresError)
						self.loadPersistentStoresAfterRemovalInteractively(completion: completion)
					}
					return
				}
			}
		}
	}
	
	func loadPersistentStoresAfterRemovalInteractively(completion: @escaping (Error?) -> ()) {
		
		do {
			try Activity.label("Erasing persistent stores as part of recovery") {
				try erasePersistentStores()
			}
		} catch {
			
			completion(error)
			return
		}
		
		Activity(named: "Loading persistent stores after erasing").execute { done in
			
			loadPersistentStores { error in
				DispatchQueue.main.async {
					defer { done() }
					
					if let loadPersistentStoresError = error {
						x$(loadPersistentStoresError)
						presentErrorMessage(NSLocalizedString("Something went wrong. Offline data might be unavailable. Please re-install the application to avoid further problems.", comment: ""))
						return
					}
					
					presentErrorMessage(NSLocalizedString("Something went wrong. Offline data has been erased.", comment: ""))
				}
			}
		}
	}
	
	// MARK: -
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
		
		x$(self)

		loadPersistentStoresInteractively { error in
			
			_ = x$(error)
		}
		
		return true
	}
	
	override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		defer { Activity(named: "Post Launch").execute {} }
		
		return Activity.label("Finishing Launching") {
			
			guard super.application(application, didFinishLaunchingWithOptions: launchOptions) else {
				return false
			}
			
			_ = mainScene
			_ = rssSession

			return true
		}
	}
	
	// MARK: -
	
	override init() {
		
		super.init()
		configureAppearance()
	}
}
