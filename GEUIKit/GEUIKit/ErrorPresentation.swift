//
//  ErrorPresentation.swift
//  GEUIKit
//
//  Created by Grigory Entin on 10.12.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import UIKit.UIAlertController
import Foundation

extension NSError {
	
	/// Puts `localizedDescription` together with `localizedFailureReason` and `localizedRecoverySuggestion`, if any.
	var combinedLocalizedDescription: String {
		switch (localizedFailureReason, localizedRecoverySuggestion) {
		case (let localizedFailureReason?, let localizedRecoverySuggestion?):
			return String.localizedStringWithFormat(
				NSLocalizedString("%@ %@ %@", comment: "Format for error message with both failure reason and recovery suggestion"),
				localizedDescription,
				localizedFailureReason,
				localizedRecoverySuggestion
			)
		case (let localizedFailureReason?, nil):
			return String.localizedStringWithFormat(
				NSLocalizedString("%@ %@", comment: "Format for error message with failure reason"),
				localizedDescription,
				localizedFailureReason
			)
		case (nil, let localizedRecoverySuggestion?):
			return String.localizedStringWithFormat(
				NSLocalizedString("%@ %@", comment: "Format for error message with recovery suggestion"),
				localizedDescription,
				localizedRecoverySuggestion
			)
		case (nil, nil):
			return localizedDescription
		}
	}
	
	var combinedLocalizedFailureReasonAndRecoverySuggestion: String? {
		switch (localizedFailureReason, localizedRecoverySuggestion) {
		case (let localizedFailureReason?, let localizedRecoverySuggestion?):
			return String.localizedStringWithFormat(
				NSLocalizedString("%@ %@", comment: "Format for error message with both failure reason and recovery suggestion"),
				localizedFailureReason,
				localizedRecoverySuggestion
			)
		case (let localizedFailureReason?, nil):
			return localizedFailureReason
		case (nil, let localizedRecoverySuggestion?):
			return localizedRecoverySuggestion
		case (nil, nil):
			return nil
		}
	}
}

extension UIAlertController {

	/// Creates and returns a view controller for displaying alert for the given error to the user, accounting `localizedFailureReason`, `localizedRecoverySuggestion`, as well as `recoveryAttempter` and `localizedRecoveryOptions`.
	///
	/// - Parameters:
	///   - rawError: Error to present
	///   - customTitle: The title for alert. If set, localizedDescription will be made part of the message. If not set, `localizedErrorDescription` is used as the title.
	convenience init(for rawError: Error, customTitle: String? = nil) {
		let error = rawError as NSError
		let title = customTitle ?? error.localizedDescription
		let message = (nil != customTitle) ? error.combinedLocalizedDescription : error.combinedLocalizedFailureReasonAndRecoverySuggestion
		self.init(title: title, message: message, preferredStyle: .alert)
		if let recoveryAttempter = error.recoveryAttempter as! NSObjectProtocol?, let recoveryOptions = error.localizedRecoveryOptions {
			for (optionIndex, recoveryOption) in recoveryOptions.enumerated() {
				addAction(UIAlertAction(title: recoveryOption, style: .default) { _ in
					let sel = #selector(NSObject.attemptRecovery(fromError:optionIndex:))
					let method = class_getInstanceMethod(type(of: recoveryAttempter), sel)!
					typealias AttemptRecoveryFromErrorOptionIndexIMP = @convention(c) (AnyObject?, Selector, AnyObject?, Int) -> Void
					let imp = unsafeBitCast(method_getImplementation(method), to: AttemptRecoveryFromErrorOptionIndexIMP.self)
					imp(recoveryAttempter, sel, error, optionIndex)
				})
			}
		}
		else {
			addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
		}
	}

}

extension UIViewController {

	public func present(_ error: Error) {
        let alert = UIAlertController(for: error)
        self.present(alert, animated: true)
	}
	
	public func present(_ error: Error, customTitle: String) {
        let alert = UIAlertController(for: error, customTitle: customTitle)
        self.present(alert, animated: true)
	}
	
}
