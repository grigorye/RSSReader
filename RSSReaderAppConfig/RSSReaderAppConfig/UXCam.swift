//
//  UXCam.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if ANALYTICS_ENABLED && UXCAM_ENABLED
	import UXCam
	import Foundation
#endif

let uxcamInitializer: Void = {
	#if ANALYTICS_ENABLED && UXCAM_ENABLED
		UXCam.startWithKey("0fc8e6e128fa538")
	#endif
}()
