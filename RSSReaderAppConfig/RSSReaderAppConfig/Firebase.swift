//
//  Firebase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 26.11.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !FIREBASE_ENABLED
	
	func configureFirebase() {
	}
	
#else
	
	import FirebaseCore
	import Foundation
	
	func configureFirebase() {
		FirebaseApp.configure()
	}
	
#endif

