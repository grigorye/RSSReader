//
//  UIView+Cloning.swift
//  GEUIKit
//
//  Created by Grigory Entin on 31/01/2019.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

extension UIView {
	
	public func clone() -> UIView {
		let archivedData = NSKeyedArchiver.archivedData(withRootObject: self)
		let unarchivedObject = NSKeyedUnarchiver.unarchiveObject(with: archivedData)
		return unarchivedObject as! UIView
	}
}
