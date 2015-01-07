//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData

struct LoginAndPassword {
	let login: String?
	let password: String?
	func isValid() -> Bool {
		return (login != nil) && (password != nil)
	}
}

func == (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
    return (left.login == right.login) && (left.password == right.password)
}
func != (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
    return !(left == right)
}
let defaults = NSUserDefaults()

class AppDelegateInternals {
	var rssSession: RSSSession? = nil
	let (managedObjectContextError, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext): (NSError?, NSManagedObjectContext?, NSManagedObjectContext?) = {
		let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)!
		let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let error: NSError? = {
			let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
			let documentsDirectory = paths[0] as NSString
			let fileManager = NSFileManager.defaultManager()
			if !fileManager.fileExistsAtPath(documentsDirectory) {
				var documentsDirectoryCreationError: NSError?
				if !fileManager.createDirectoryAtPath(documentsDirectory, withIntermediateDirectories: true, attributes: nil, error: &documentsDirectoryCreationError) {
					return trace("documentsDirectoryCreationError", documentsDirectoryCreationError)
				}
			}
			let storeURL = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("RSSReader.sqlite"))!
			let addPersistentStoreMigratedError: NSError? = {
				var addPersistentStoreError: NSError?
				let options = [
					NSMigratePersistentStoresAutomaticallyOption: true,
					NSInferMappingModelAutomaticallyOption: true
				]
				let persistentStore: NSPersistentStore! = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options, error: &addPersistentStoreError)
				if nil != persistentStore {
					return nil
				}
				let error = trace("addPersistentStoreError", addPersistentStoreError!)
				switch (error.domain, error.code) {
					case (NSCocoaErrorDomain, NSPersistentStoreIncompatibleVersionHashError), (NSCocoaErrorDomain, NSMigrationError):
						let fileManager = NSFileManager.defaultManager()
						var incompatibleStoreRemovalError: NSError?
						if !fileManager.removeItemAtURL(storeURL, error: &incompatibleStoreRemovalError) {
							return trace("incompatibleStoreRemovalError", incompatibleStoreRemovalError)
						}
						var addReplacementPersistentStoreError: NSError?
						let persistentStore: NSPersistentStore! = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &addReplacementPersistentStoreError)
						if nil == persistentStore {
							return trace("addReplacementPersistentStoreError", addReplacementPersistentStoreError)
						}
						return nil
					default:
						let nonRecoverableAddPersistentStoreError = addPersistentStoreError!
						return trace("nonRecoverableAddPersistentStoreError", nonRecoverableAddPersistentStoreError)
				}
			}()
			if let addPersistentStoreMigratedError = addPersistentStoreMigratedError {
				return trace("addPersistentStoreMigratedError", addPersistentStoreMigratedError)
			}
			return nil
		}()
		if let error = error {
			return (error, nil, nil)
		}
		let mainQueueManagedObjectContext: NSManagedObjectContext = {
			let $ = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
			$.persistentStoreCoordinator = psc
			return $
		}()
		let backgroundQueueManagedObjectContext: NSManagedObjectContext = {
			let $ = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
			$.parentContext = mainQueueManagedObjectContext
			return $
		}()
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: mainQueueManagedObjectContext, queue: nil, usingBlock: { (_) -> Void in
			mainQueueManagedObjectContext.performBlock {
				var mainQueueManagedObjectContextSaveError: NSError?
				mainQueueManagedObjectContext.save(&mainQueueManagedObjectContextSaveError)
				trace("mainQueueManagedObjectContextSaveError", mainQueueManagedObjectContextSaveError)
			}
		})
		return (nil, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext)
	}()
}

extension RSSSession {
	var authToken: NSString! {
		get {
			return defaults.authToken
		}
		set {
			defaults.authToken = newValue
		}
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	let internals = AppDelegateInternals()
	var loginAndPassword: LoginAndPassword {
        didSet {
            if loginAndPassword != oldValue  {
				if loginAndPassword.isValid() {
					self.rssSession = RSSSession(loginAndPassword: loginAndPassword)
					self.rssSession.authenticate()
				}
            }
        }
	}
	func proceedWithManagedObjectContext() {
		if self.loginAndPassword.isValid() {
			let rssSession = RSSSession(loginAndPassword: self.loginAndPassword)
			self.rssSession = rssSession
			if (rssSession.authToken == nil) {
				rssSession.authenticate()
			}
			else {
				rssSession.postprocessAuthentication()
			}
		}
		else {
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
			}
		}
	}
	override init() {
		let defaults = NSUserDefaults()
		self.loginAndPassword = defaults.loginAndPassword
	}
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		let notificationCenter = NSNotificationCenter.defaultCenter()
		var handlingNotification = false
		notificationCenter.addObserverForName(NSUserDefaultsDidChangeNotification, object: nil, queue: nil) { (_: NSNotification!) -> Void in
			if !handlingNotification {
				handlingNotification = true
				let defaults = NSUserDefaults()
				let loginAndPassword = defaults.loginAndPassword
				if self.loginAndPassword != loginAndPassword {
					self.loginAndPassword = loginAndPassword
				}
				let authToken = defaults.authToken
				if let authToken = authToken {
					self.rssSession.authToken = authToken
				}
				handlingNotification = false
			}
		}
		assert(nil == self.internals.managedObjectContextError, "")
		if let managedObjectContextError = self.internals.managedObjectContextError {
			trace("managedObjectContextError", managedObjectContextError)
			return false
		}
		else {
			self.proceedWithManagedObjectContext()
		}
		return true
	}
}

