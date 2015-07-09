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
	let (managedObjectContextError, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext): (ErrorType?, NSManagedObjectContext?, NSManagedObjectContext?) = {
		do {
			let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)!
			let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
			let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
			let documentsDirectory = paths[0]
			let fileManager = NSFileManager.defaultManager()
			if !fileManager.fileExistsAtPath(documentsDirectory) {
				try fileManager.createDirectoryAtPath(documentsDirectory, withIntermediateDirectories: true, attributes: nil)
			}
			let storeURL = NSURL.fileURLWithPath(documentsDirectory.stringByAppendingPathComponent("RSSReader.sqlite"))
			$(fileManager.fileExistsAtPath(storeURL.path!)).$()
			if NSUserDefaults().boolForKey("forceStoreRemoval") {
				let fileManager = NSFileManager.defaultManager()
				do {
					try fileManager.removeItemAtURL(storeURL)
				}
				catch NSCocoaError.FileNoSuchFileError {
				}
			}
			do {
				let options = [
					NSMigratePersistentStoresAutomaticallyOption: true,
					NSInferMappingModelAutomaticallyOption: true
				]
				let persistentStore = try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
			} catch let error as NSCocoaError {
				switch error.rawValue {
				case NSMigrationMissingSourceModelError where NSUserDefaults().boolForKey("allowMissingSourceModelError"):
				fallthrough
				case NSPersistentStoreIncompatibleVersionHashError, NSMigrationError:
					let fileManager = NSFileManager.defaultManager()
					try fileManager.removeItemAtURL(storeURL)
					try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
				default:
					throw error
				}
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
					try! mainQueueManagedObjectContext.save()
				}
			})
			return (nil, mainQueueManagedObjectContext, backgroundQueueManagedObjectContext)
		}
		catch {
			return (error, nil, nil)
		}
	}()
	init() {
		let taskGenerator = progressEnabledURLSessionTaskGenerator
		urlTaskGeneratorProgressKVOBinding = KVOBinding(taskGenerator•{"progresses"}, options: []) { change in
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
	dynamic var foldersUpdateStateRaw: String = FoldersUpdateState.Completed.rawValue
	var foldersUpdateState = FoldersUpdateState.Completed {
		didSet {
			foldersUpdateStateRaw = foldersUpdateState.rawValue
		}
	}
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
		let _ = "foo" as AnyObject as! Int
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
			UXCam.startWithKey("0fc8e6e128fa538")
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
		let libraryDirectoryURL = fileManager.URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).last!
		let libraryDirectory = libraryDirectoryURL.path!
        $(libraryDirectory).$()
	}
}
