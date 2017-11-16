//
// Created by Grigory Entin on 12.02.15.
// Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit.UITabBarController

extension UITabBarController {
    func topViewController() -> UIViewController? {
        return self.selectedViewController
    }
}
