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
	
	func loadPersistentStoresInteractively(completion: @escaping (Error?) -> ()) {
		
		var scope = Activity("Loading Persistent Stores").enter()
		
		loadPersistentStores { error in
			
			if let loadPersistentStoresError = error {
				
				trackError(x$(loadPersistentStoresError))
				
				DispatchQueue.main.async {
					
					x$(loadPersistentStoresError)
					self.loadPersistentStoresAfterRemovalInteractively(completion: completion)
					scope.leave()
				}
				
				return
			}
			
			scope.leave()
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
				
				if let loadPersistentStoresError = error {
					
					x$(loadPersistentStoresError)
					presentErrorMessage(NSLocalizedString("Something went wrong. Offline data might be unavailable. Please re-install the application to avoid further problems.", comment: ""))
					return
				}
				
				presentErrorMessage(NSLocalizedString("Something went wrong. Offline data has been erased.", comment: ""))
			}
		}
	}
	
	// MARK: -
	
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
		
		x$(self)

		loadPersistentStoresInteractively { error in
			
			_ = x$(error)
		}
		
		return true
	}
	
	override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		
		defer { launchingScope.leave() }
		
		var scope = Activity("Finishing Launching").enter(); defer { scope.leave() }
		
		guard super.application(application, didFinishLaunchingWithOptions: launchOptions) else {
			
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
