//
//  UIDataSourceModelAssociation+NilIndexPathInModelIdentifierForElement.swift
//  GEBase
//
//  Created by Grigory Entin on 05.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import UIKit

public
extension UIDataSourceModelAssociation {
	typealias _Self = UIDataSourceModelAssociation
	static func adjustForNilIndexPathPassedToModelIdentifierForElement() {
		typealias ImpBlock = @convention(block) (_Self?, NSIndexPath?, UIView?) -> String?
		typealias Imp = @convention(c) (_Self?, Selector, NSIndexPath?, UIView?) -> String?
		let sel = #selector(self.modelIdentifierForElement(at:in:))
		let method = class_getInstanceMethod(self, sel)!
		let oldImp: Imp = unsafeBitCast(method_getImplementation(method), to: Imp.self)
		let impBlock: ImpBlock = { pself, indexPath, view in
			guard let indexPath = indexPath else {
				return nil
			}
			return oldImp(pself, sel, indexPath, view)
		}
		let imp = imp_implementationWithBlock(unsafeBitCast(impBlock, to: AnyObject.self))
		method_setImplementation(method, imp)
	}
}
