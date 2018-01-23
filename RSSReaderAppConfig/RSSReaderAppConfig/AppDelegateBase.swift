//
//  AppDelegateBase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 08/10/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import func GEUIKit.openSettingsApp
import GEDebugKit
import func GEFoundation.loadDefaultsFromSettingsPlistAtURL
import var GEFoundation.versionIsClean
import var GEFoundation.buildAge
#if DEBUG
import var GEFoundation.nslogRedirectorInitializer
#endif
import Loggy
import UIKit

let analyticsShouldBeEnabled: Bool = {
	let mainBundleURL = Bundle.main.bundleURL
	return x$(versionIsClean) && !x$(mainBundleURL).lastPathComponent.hasPrefix("Test")
}()

open class AppDelegateBase : UIResponder, UIApplicationDelegate {
	public var window: UIWindow?
	final var retainedObjects = [Any]()
	// MARK: -
	@IBAction public func openSettings(_ sender: AnyObject?) {
		openSettingsApp()
	}
	// MARK: -
	open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        configureDebug()
        
		#if false
		if x$(analyticsShouldBeEnabled) {
			launchOptimizely(launchOptions: launchOptions)
			configureFirebase()
		}
		#endif
		return true
	}
	// MARK: -
	public override init() {
		_ = AppDelegateBase.initializeOnce
		super.init()
		var scope = Activity("Basic Initialization").enter(); defer { scope.leave() }
		let defaultsPlistURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
		try! loadDefaultsFromSettingsPlistAtURL(defaultsPlistURL)
        
        initializeDebug()
        
		let fileManager = FileManager()
		let libraryDirectoryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).last!
		let libraryDirectory = libraryDirectoryURL.path
        x$(libraryDirectory)
	}
	// MARK: -
	static private let initializeOnce: Ignored = {
		var scope = Activity("Initializing Analytics").enter(); defer { scope.leave() }
		#if DEBUG
			_ = nslogRedirectorInitializer
		#endif
		#if WATCHDOG_ENABLED
			_ = watchdogInitializer
		#endif
		x$(buildAge)
		if x$(analyticsShouldBeEnabled) {
			_ = crashlyticsInitializer
			_ = appseeInitializer
			_ = uxcamInitializer
			_ = flurryInitializer
			_ = mixpanelInitializer
		}
		return Ignored()
	}()
}
