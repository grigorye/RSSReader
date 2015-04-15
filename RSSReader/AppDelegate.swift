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
	let login: String?
	let password: String?
	func isValid() -> Bool {
		return (login != nil) && (password != nil)
	}
	init(login: String?, password: String?) {
		self.login = login
		self.password = password
	}
}

func == (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
	return (left.login == right.login) && (left.password == right.password)
}
func != (left: LoginAndPassword, right: LoginAndPassword) -> Bool {
	return !(left == right)
}

class AppDelegateInternals {
	var rssSession: RSSSession?
	private let urlTaskGeneratorProgressKVOBinding: KVOBinding
	let progressEnabledURLSessionTaskGenerator = ProgressEnabledURLSessionTaskGenerator()
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
					return $(documentsDirectoryCreationError).$()
				}
			}
			let storeURL = NSURL(fileURLWithPath: documentsDirectory.stringByAppendingPathComponent("RSSReader.sqlite"))!
			$(fileManager.fileExistsAtPath(storeURL.path!)).$()
			if NSUserDefaults().boolForKey("forceStoreRemoval") {
				let fileManager = NSFileManager.defaultManager()
				var forcedStoreRemovalError: NSError?
				if !fileManager.removeItemAtURL(storeURL, error: &forcedStoreRemovalError) && !((NSCocoaErrorDomain == forcedStoreRemovalError!.domain) && (NSFileNoSuchFileError == forcedStoreRemovalError!.code)) {
					return $(forcedStoreRemovalError).$()
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
				let error = $(addPersistentStoreError!).$()
				switch (error.domain, error.code) {
					case (NSCocoaErrorDomain, NSMigrationMissingSourceModelError) where NSUserDefaults().boolForKey("allowMissingSourceModelError"):
						fallthrough
					case (NSCocoaErrorDomain, NSPersistentStoreIncompatibleVersionHashError), (NSCocoaErrorDomain, NSMigrationError):
						let fileManager = NSFileManager.defaultManager()
						var incompatibleStoreRemovalError: NSError?
						if !fileManager.removeItemAtURL(storeURL, error: &incompatibleStoreRemovalError) {
							return $(incompatibleStoreRemovalError).$()
						}
						var addReplacementPersistentStoreError: NSError?
						let persistentStore: NSPersistentStore! = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &addReplacementPersistentStoreError)
						if nil == persistentStore {
							return $(addReplacementPersistentStoreError).$()
						}
						return nil
					default:
						let nonRecoverableAddPersistentStoreError = addPersistentStoreError!
						return $(nonRecoverableAddPersistentStoreError).$()
				}
			}()
			if let addPersistentStoreMigratedError = addPersistentStoreMigratedError {
				return $(addPersistentStoreMigratedError).$()
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
					$(mainQueueManagedObjectContextSaveError).$()
				}
			}
		})
		return (nil, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext)
	}()
	init() {
		let taskGenerator = progressEnabledURLSessionTaskGenerator
		urlTaskGeneratorProgressKVOBinding = KVOBinding(object: taskGenerator, keyPath: "progresses", options: NSKeyValueObservingOptions(0)) { change in
			let networkActivityIndicatorShouldBeVisible = 0 < taskGenerator.progresses.count
			UIApplication.sharedApplication().networkActivityIndicatorVisible = $( networkActivityIndicatorShouldBeVisible).$()
		}
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
	var tabBarController: UITabBarController! {
		if let tabBarController = window!.rootViewController! as? UITabBarController {
			return tabBarController
		}
		return nil
	}
	var navigationController: UINavigationController! {
		if let navigationController = window!.rootViewController! as? UINavigationController {
			return navigationController
		}
		return nil
	}
	var foldersNavigationController: UINavigationController {
		if let tabBarController = self.tabBarController {
			return tabBarController.viewControllers![0] as! UINavigationController
		}
		else {
			return navigationController
		}
	}
	var foldersViewController: FoldersListTableViewController {
		return foldersNavigationController.viewControllers.first as! FoldersListTableViewController
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
	lazy var fetchedRootFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: self.mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(rootTagSuffix)) { folder in
		let foldersViewController = self.foldersViewController
		foldersViewController.rootFolder = folder
	}
	lazy var fetchedFavoritesFolderBinding: FetchedObjectBinding<Folder> = FetchedObjectBinding<Folder>(managedObjectContext: self.mainQueueManagedObjectContext, predicate: Folder.predicateForFetchingFolderWithTagSuffix(favoriteTagSuffix)) { folder in
		let foldersViewController = self.favoritesViewController
		foldersViewController.container = folder
	}
	// MARK: -
	private let currentRestorationFormatVersion = 1
	private enum Restorable: String {
		case restorationFormatVersion = "restorationFormatVersion"
	}
	func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
		$(self).$()
		coder.encodeObject(currentRestorationFormatVersion, forKey: Restorable.restorationFormatVersion.rawValue)
		return true
	}
	func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
		$(self).$()
		let restorationFormatVersion = (coder.decodeObjectForKey(Restorable.restorationFormatVersion.rawValue) as! Int?) ?? 0
		if restorationFormatVersion < currentRestorationFormatVersion {
			return false
		}
		return !defaults.stateRestorationDisabled
	}
	//
	func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
		$(self).$()
		return true
	}
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		hideBarsOnSwipe = nil == self.tabBarController
		assert(nil == self.internals.managedObjectContextError)
		if let managedObjectContextError = self.internals.managedObjectContextError {
			$(managedObjectContextError).$()
			presentErrorMessage(NSLocalizedString("Something went wrong.", comment: ""))
			return false
		}
		else {
			if !hideBarsOnSwipe {
				void(self.fetchedRootFolderBinding)
				void(self.fetchedFavoritesFolderBinding)
				foldersViewController.hidesBottomBarWhenPushed = false
				favoritesViewController.navigationItem.backBarButtonItem = {
					let title = NSLocalizedString("Favorites", comment: "");
					return UIBarButtonItem(title: title, style: .Plain, target: nil, action: nil)
				}()
			}
			if !loginAndPassword.isValid() {
				self.openSettings(nil)
			}
			else {
				self.rssSession = RSSSession(loginAndPassword: self.loginAndPassword)
			}
		}
		return true
	}
	// MARK: -
	override init() {
		super.init()
#if ANALYTICS_ENABLED
		let version = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! NSString
		let versionIsClean = NSNotFound == version.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).location
		if $(versionIsClean).$() && $(defaults.analyticsEnabled).$() {
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
        $(libraryDirectory).$()
	}
}

protocol FoldersController {
	func updateAllAuthenticated(completionHandler: (NSError?) -> Void)
	func updateAll(completionHandler: (NSError?) -> Void)
}

extension AppDelegate: FoldersController {
	// MARK: -
	//
	func updateAllAuthenticated(completionHandler: (NSError?) -> Void) {
		let rssSession = self.rssSession!
		rssSession.updateUserInfo { updateUserInfoError in dispatch_async(dispatch_get_main_queue()) {
			if let updateUserInfoError = updateUserInfoError {
				completionHandler(applicationError(.UserInfoRetrievalError, $(updateUserInfoError).$()))
				return
			}
			rssSession.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = updateTagsError {
					completionHandler(applicationError(.TagsUpdateError, $(updateTagsError).$()))
					return
				}
				rssSession.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateSubscriptionsError = updateSubscriptionsError {
						completionHandler(applicationError(.TagsUpdateError, $(updateSubscriptionsError).$()))
						return
					}
					rssSession.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = updateUnreadCountsError {
							completionHandler(applicationError(.TagsUpdateError, $(updateUnreadCountsError).$()))
							return
						}
						rssSession.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = updateStreamPreferencesError {
								completionHandler(applicationError(.StreamPreferencesUpdateError, $(updateStreamPreferencesError).$()))
								return
							}
							completionHandler(nil)
						}}
					}}
				}}
			}}
		}}
	}
	func updateAll(completionHandler: (NSError?) -> Void) {
		let rssSession = self.rssSession!
		let postAuthenticate = { () -> Void in
			self.updateAllAuthenticated(completionHandler)
		}
		if (rssSession.authToken == nil) {
			rssSession.authenticate { error in dispatch_async(dispatch_get_main_queue()) {
				if let authenticationError = error {
					completionHandler(authenticationError)
				}
				else {
					postAuthenticate()
				}
			}}
		}
		else {
			postAuthenticate()
		}
	}
}