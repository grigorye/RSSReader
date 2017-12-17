//
//  Firebase.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 26.11.2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

#if ANALYTICS_ENABLED && FIREBASE_ENABLED
	import FirebaseCore
	import Foundation
#endif

func configureFirebase() {
	#if ANALYTICS_ENABLED && FIREBASE_ENABLED
		FirebaseApp.configure()
	#endif
}
