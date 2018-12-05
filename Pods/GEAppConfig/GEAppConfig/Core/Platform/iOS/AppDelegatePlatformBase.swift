//
//  AppDelegatePlatformBase.swift
//  GEAppConfig
//
//  Created by Grigory Entin on 28/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GEDebugKit
import func GEUIKit.openSettingsApp
import var GEUIKit.urlTaskGeneratorProgressBinding
import UIKit

open class AppDelegatePlatformBase : UIResponder, UIApplicationDelegate {
	public var window: UIWindow?

    func initializeBasics() {
        let defaultsPlistURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
        try! loadDefaultsFromSettingsPlistAtURL(defaultsPlistURL)
        
        initializeDebug()
    }
    // MARK: -
    @IBAction public func openSettings(_ sender: AnyObject?) {
        openSettingsApp()
    }

    func applicationShouldHaveMainWindow() {
        
        _ = networkActivityIndicatorInitializer
    }
    
	open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        configureDebug()
        
        #if false
        if x$(analyticsShouldBeEnabled) {
            launchOptimizely(launchOptions: launchOptions)
            configureFirebase()
        }
        #endif
        
        _ = urlTaskGeneratorProgressBinding
        
        DispatchQueue.main.async {
            
            self.applicationShouldHaveMainWindow()
        }
        return true
    }
}
