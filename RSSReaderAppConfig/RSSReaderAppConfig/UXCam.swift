//
//  UXCam.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

#if !ANALYTICS_ENABLED || !UXCAM_ENABLED

public let uxcamInitializer: Void = ()

#else

import UXCam
import Foundation

public let uxcamInitializer: Void = {
	UXCam.startWithKey("0fc8e6e128fa538")
}()

#endif
