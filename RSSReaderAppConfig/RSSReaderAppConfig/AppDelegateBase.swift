//
//  AppDelegateBase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 08/10/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import func GEUIKit.openSettingsApp
import func GEFoundation.loadDefaultsFromSettingsPlistAtURL
import var GEFoundation.versionIsClean
import var GEFoundation.buildAge
#if DEBUG
import var GEFoundation.nslogRedirectorInitializer
#endif
import Loggy
import FBAllocationTracker
import FBMemoryProfiler
import UIKit

extension TypedUserDefaults {
    @NSManaged public var memoryProfilerEnabled: Bool
    @NSManaged public var allocationTrackingEnabled: Bool
}

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
        if _1 {
            if defaults.memoryProfilerEnabled {
                let memoryProfiler = FBMemoryProfiler()
                memoryProfiler.enable()
                retainedObjects += [memoryProfiler]
            }
        }
        else {
            var memoryProfiler: FBMemoryProfiler!
            retainedObjects += [defaults.observe(\.memoryProfilerEnabled, options: .initial) { (_, _) in
                if defaults.memoryProfilerEnabled {
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
		if defaults.allocationTrackingEnabled {
			FBAllocationTrackerManager.shared()!.startTrackingAllocations()
			FBAllocationTrackerManager.shared()!.enableGenerations()
		}
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
