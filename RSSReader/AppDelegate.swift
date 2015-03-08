//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Grigory Entin on 31.12.14.
//  Copyright (c) 2014 Grigory Entin. All rights reserved.
//

import UIKit
import CoreData
#if ANALYTICS_ENABLED
#if CRASHLYTICS_ENABLED
import Fabric
import Crashlytics
#endif
#if APPSEE_ENABLED
import Appsee
#endif
#endif

struct LoginAndPassword {
	let login: String? = nil
	let password: String? = nil
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

class AppDelegateInternals {
	var rssSession: RSSSession! = nil
	private var urlTaskGeneratorProgressKVOBinding: KVOBinding!
	var progressEnabledURLSessionTaskGenerator = ProgressEnabledURLSessionTaskGenerator() {
		didSet {
			let taskGenerator = oldValue
			self.urlTaskGeneratorProgressKVOBinding = KVOBinding(object: taskGenerator, keyPath: "progresses", options: NSKeyValueObservingOptions(0)) { change in
				UIApplication.sharedApplication().networkActivityIndicatorVisible = 0 < taskGenerator.progresses.count
			}
		}
	}
	let (managedObjectContextError, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext): (NSError?, NSManagedObjectContext?, NSManagedObjectContext?) = {
		let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)!
		let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		let error: NSError? = {
			let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)  as! [String]
			let documentsDirectory = paths[0]
			let fileManager = NSFileManager.defaultManager()
			if !fileManager.fileExistsAtPath(documentsDirectory) {
				var documentsDirectoryCreationError: NSError?
				if !fileManager.createDirectoryAtPath(documentsDirectory, withIntermediateDirectories: true, attributes: nil, error: &documentsDirectoryCreationError) {
					return trace("documentsDirectoryCreationError", documentsDirectoryCreationError)
				}
			}
			let storeURL = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("RSSReader.sqlite"))!
			void(trace("fileManager.fileExistsAtPath(storeURL.path!)", fileManager.fileExistsAtPath(storeURL.path!)))
			if NSUserDefaults().boolForKey("forceStoreRemoval") {
				let fileManager = NSFileManager.defaultManager()
				var forcedStoreRemovalError: NSError?
				if !fileManager.removeItemAtURL(storeURL, error: &forcedStoreRemovalError) && !((NSCocoaErrorDomain == forcedStoreRemovalError!.domain) && (NSFileNoSuchFileError == forcedStoreRemovalError!.code)) {
					return trace("forcedStoreRemovalError", forcedStoreRemovalError)
				}
			}
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
					case (NSCocoaErrorDomain, NSMigrationMissingSourceModelError) where NSUserDefaults().boolForKey("allowMissingSourceModelError"):
						fallthrough
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
		notificationCenter.addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: mainQueueManagedObjectContext, queue: nil, usingBlock: { _ in
			mainQueueManagedObjectContext.performBlock {
				var mainQueueManagedObjectContextSaveError: NSError?
				mainQueueManagedObjectContext.save(&mainQueueManagedObjectContextSaveError)
				if nil != mainQueueManagedObjectContextSaveError {
					trace("mainQueueManagedObjectContextSaveError", mainQueueManagedObjectContextSaveError)
				}
			}
		})
		return (nil, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext)
	}()
	init () {
	}
}

extension RSSSession {
	var authToken: String! {
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
	var tabBarController: UITabBarController {
		return window!.rootViewController! as! UITabBarController
	}
	var foldersViewController: FoldersListTableViewController {
		return (tabBarController.viewControllers![0] as! UINavigationController).viewControllers.first as! FoldersListTableViewController
	}
	var favoritesViewController: ItemsListViewController {
		return (tabBarController.viewControllers![1] as! UINavigationController).viewControllers.first as! ItemsListViewController
	}
	var loginAndPassword: LoginAndPassword {
		return defaults.loginAndPassword
	}
	// MARK: -
	@IBAction func openSettings(sender: AnyObject?) {
		UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
	}
	@IBAction func crash(sender: AnyObject?) {
		let x = "foo" as AnyObject as! Int
	}
	// MARK: -
	func postprocessAuthentication(completionHandler: (NSError?) -> Void) {
		rssSession.updateUserInfo { updateUserInfoError in dispatch_async(dispatch_get_main_queue()) {
			if let updateUserInfoError = trace("updateUserInfoError", updateUserInfoError) {
				presentErrorMessage(NSLocalizedString("Failed to retrieve user info.", comment: ""))
				completionHandler(updateUserInfoError)
				return
			}
			self.rssSession.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = trace("updateTagsError", updateTagsError) {
					presentErrorMessage(NSLocalizedString("Failed to update tags.", comment: ""))
					completionHandler(updateTagsError)
					return
				}
				self.rssSession.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateTagsError = trace("updateSubscriptionsError", updateSubscriptionsError) {
						presentErrorMessage(NSLocalizedString("Failed to update subscriptions.", comment: ""))
						completionHandler(updateSubscriptionsError)
						return
					}
					self.rssSession.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = trace("updateUnreadCountsError", updateUnreadCountsError) {
							presentErrorMessage(NSLocalizedString("Failed to update unread counts.", comment: ""))
							completionHandler(updateUnreadCountsError)
							return
						}
						self.rssSession.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = trace("updateUnreadCountsError", trace("updateStreamPreferencesError", updateStreamPreferencesError)) {
								completionHandler(updateStreamPreferencesError)
								return
							}
							completionHandler(nil)
						}}
					}}
				}}
			}}
		}}
	}
	func proceedWithManagedObjectContext() {
		if self.loginAndPassword.isValid() {
			let rssSession = RSSSession(loginAndPassword: self.loginAndPassword)
			self.rssSession = rssSession
			if _1 {
			let postAuthenticate = { () -> Void in
				self.postprocessAuthentication { error in
					dispatch_async(dispatch_get_main_queue()) {
						if let error = error {
							presentErrorMessage(NSLocalizedString("Got a problem with feeds retrieval.", comment: ""))
						}
						else {
							presentInfoMessage(NSLocalizedString("Feeds have been retrieved.", comment: ""))
						}
					}
				}
			}
			if (rssSession.authToken == nil) {
				rssSession.authenticate { error in
					dispatch_async(dispatch_get_main_queue()) {
						if let error = error {
							presentErrorMessage(NSLocalizedString("Authentication failed.", comment: ""))
						}
						else {
							postAuthenticate()
						}
					}
				}
			}
			else {
				postAuthenticate()
			}
			}
		}
		else {
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
			}
		}
	}
	lazy var fetchedRootFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: self.mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(rootTagSuffix)) { folder in
		let foldersViewController = self.foldersViewController
		foldersViewController.rootFolder = folder
	}
	lazy var fetchedFavoritesFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: self.mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(favoriteTagSuffix)) { folder in
		let foldersViewController = self.favoritesViewController
		foldersViewController.folder = folder
	}
	// MARK: -
	func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		void(trace("self", self))
		return true
	}
	func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		void(trace("self", self))
		return !defaults.stateRestorationDisabled
	}
	func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
		void(trace("self", self))
		return true
	}
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		assert(nil == self.internals.managedObjectContextError, "")
		if let managedObjectContextError = self.internals.managedObjectContextError {
			void(trace("managedObjectContextError", managedObjectContextError))
			presentErrorMessage(NSLocalizedString("Something went wrong.", comment: ""))
			return false
		}
		else {
			void(self.fetchedRootFolderBinding)
			void(self.fetchedFavoritesFolderBinding)
			foldersViewController.hidesBottomBarWhenPushed = false
			favoritesViewController.navigationItem.backBarButtonItem = {
				let title = NSLocalizedString("Favorites", comment: "");
				return UIBarButtonItem(title: title, style: .Plain, target: nil, action: nil)
			}()
			proceedWithManagedObjectContext()
		}
		return true
	}
	// MARK: -
	override init() {
		super.init()
#if ANALYTICS_ENABLED
		let version = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! NSString
		let versionIsClean = NSNotFound == version.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).location
		if trace("versionIsClean", versionIsClean) && trace("analyticsEnabled", defaults.analyticsEnabled) {
#if CRASHLYTICS_ENABLED
			Fabric.with([Crashlytics()])
#endif
#if UXCAM_ENABLED
			UXCam.startApplicationWithKey("0fc8e6e128fa538")
#endif
#if FLURRY_ENABLED
			Flurry.startSession("TSPCHYJBMBGZZFM3SFDZ")
#endif
#if APPSEE_ENABLED
			Appsee.start(NSBundle.mainBundle().infoDictionary!["appseeAPIKey"] as! String)
#endif
		}
#endif
		let fileManager = NSFileManager()
		let libraryDirectoryURL = fileManager.URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).last as! NSURL
		let libraryDirectory = libraryDirectoryURL.path!
		trace("libraryDirectory", libraryDirectory)
	}
}

