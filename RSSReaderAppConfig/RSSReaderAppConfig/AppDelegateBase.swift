//
//  AppDelegateBase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 08/10/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import func GEUIKit.openSettingsApp
import func GEUIKit.forceCrash
import func GEFoundation.loadDefaultsFromSettingsPlistAtURL
import var GEFoundation.versionIsClean
import var GEFoundation.buildAge
import var GEFoundation.nslogRedirectorInitializer
import FirebaseCore
import Loggy
import FBAllocationTracker
import FBMemoryProfiler
import UIKit

let triggeredError = NSError(domain: "com.grigorye.triggered", code: 1)

extension TypedUserDefaults {
	@NSManaged public var memoryProfilingEnabled: Bool
}

let analyticsShouldBeEnabled: Bool = {
	let mainBundleURL = Bundle.main.bundleURL
	return $(versionIsClean) && !$(mainBundleURL).lastPathComponent.hasPrefix("Test")
}()

open class AppDelegateBase : UIResponder, UIApplicationDelegate {
	public var window: UIWindow?
	final var retainedObjects = [Any]()
	// MARK: -
	@IBAction public func openSettings(_ sender: AnyObject?) {
		openSettingsApp()
	}
	@IBAction public func forceCrash(_ sender: AnyObject?) {
		GEUIKit.forceCrash()
	}
	@IBAction public func triggerError(_ sender: AnyObject?) {
		trackError(triggeredError)
	}
	// MARK: -
	open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		if _1 {
			if defaults.memoryProfilingEnabled {
				let memoryProfiler = FBMemoryProfiler()
				memoryProfiler.enable()
				retainedObjects += [memoryProfiler]
			}
		}
		else {
			var memoryProfiler: FBMemoryProfiler!
			retainedObjects += [KVOBinding(defaults•#keyPath(TypedUserDefaults.memoryProfilingEnabled), options: .initial) { change in
				if defaults.memoryProfilingEnabled {
					guard nil == memoryProfiler else {
						return
					}
					memoryProfiler = FBMemoryProfiler()
					memoryProfiler.enable()
				}
				else {
					guard nil != memoryProfiler else {
						return
					}
					memoryProfiler.disable()
					memoryProfiler = nil
				}
			}]
		}
		if $(analyticsShouldBeEnabled) {
			launchOptimizely(launchOptions: launchOptions)
			FIRApp.configure()
		}
		return true
	}
	// MARK: -
	public override init() {
		_ = AppDelegateBase.initializeOnce
		super.init()
		var scope = Activity("Basic Initialization").enter(); defer { scope.leave() }
		let defaultsPlistURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
		try! loadDefaultsFromSettingsPlistAtURL(defaultsPlistURL)
		if defaults.memoryProfilingEnabled {
			FBAllocationTrackerManager.shared()!.startTrackingAllocations()
			FBAllocationTrackerManager.shared()!.enableGenerations()
		}
		let fileManager = FileManager()
		let libraryDirectoryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).last!
		let libraryDirectory = libraryDirectoryURL.path
        $(libraryDirectory)
	}
	// MARK: -
	static private let initializeOnce: Ignored = {
		var scope = Activity("Initializing Analytics").enter(); defer { scope.leave() }
		_ = nslogRedirectorInitializer
		$(buildAge)
		if $(analyticsShouldBeEnabled) {
			_ = crashlyticsInitializer
			_ = appseeInitializer
			_ = uxcamInitializer
			_ = flurryInitializer
			_ = mixpanelInitializer
		}
		return Ignored()
	}()
}
