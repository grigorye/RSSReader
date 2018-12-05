//
//  AppDelegateBase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 08/10/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import var GEFoundation.versionIsClean
import var GEFoundation.buildAge
#if DEBUG
import var GEFoundation.nslogRedirectorInitializer
#endif
import typealias GEFoundation.Ignored
import func GETracing.x$
#if GEAPPCONFIG_LOGGY_ENABLED
import Loggy
#endif

let analyticsShouldBeEnabled: Bool = {
	let mainBundleURL = Bundle.main.bundleURL
	return x$(versionIsClean) && !x$(mainBundleURL).lastPathComponent.hasPrefix("Test")
}()

open class AppDelegateBase : AppDelegatePlatformBase {
    
	final var retainedObjects = [Any]()
    
	// MARK: -
    
    override func initializeBasics() {
        
        super.initializeBasics()
        
        let fileManager = FileManager()
        let libraryDirectoryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).last!
        let libraryDirectory = libraryDirectoryURL.path
        x$(libraryDirectory)
    }
    
	public override init() {
		_ = AppDelegateBase.initializeOnce
		super.init()
        #if GEAPPCONFIG_LOGGY_ENABLED
		Activity.label("Basic Initialization") {
            initializeBasics()
		}
        #else
        initializeBasics()
        #endif
	}
    
	// MARK: -
    
    private static func initializeAnalytics() {
        #if DEBUG
        _ = nslogRedirectorInitializer
        #endif
        #if GEAPPCONFIG_WATCHDOG_ENABLED
        _ = watchdogInitializer
        #endif
        _ = fileLoggerInitializer
        x$(buildAge)
        #if GEAPPCONFIG_COREDATA_ENABLED
        _ = coreDataDiagnosticsInitializer
        #endif
        if x$(analyticsShouldBeEnabled) {
            #if GEAPPCONFIG_CRASHLYTICS_ENABLED
            _ = crashlyticsInitializer
            #endif
            #if GEAPPCONFIG_ANSWERS_ENABLED
            _ = answersInitializer
            #endif
            #if GEAPPCONFIG_APPSEE_ENABLED
            _ = appseeInitializer
            #endif
            #if GEAPPCONFIG_UXCAM_ENABLED
            _ = uxcamInitializer
            #endif
            #if GEAPPCONFIG_FLURRY_ENABLED
            _ = flurryInitializer
            #endif
            #if GEAPPCONFIG_MIXPANEL_ENABLED
            _ = mixpanelInitializer
            #endif
        }
    }

	static private let initializeOnce: Ignored = {
        #if GEAPPCONFIG_LOGGY_ENABLED
		return Activity.label("Initializing Analytics") {
            initializeAnalytics()
			return Ignored()
		}
        #else
        initializeAnalytics()
        return Ignored()
        #endif
	}()
}
