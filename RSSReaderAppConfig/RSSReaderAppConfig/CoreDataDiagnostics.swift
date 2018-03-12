//
//  CoreDataDiagnostics.swift
//  RSSReaderAppConfig
//
//  Created by Grigory Entin on 12.03.2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GETracing
import GECoreData
import Foundation

private func enableCoreDataAwareErrorDescriptions() {
	let oldTracedValueDescriptionGenerator = tracedValueDescriptionGenerator
	tracedValueDescriptionGenerator = {
		switch $0 {
		case let error as Error:
			return coreDataAwareDescription(of: error)
		default:
			return oldTracedValueDescriptionGenerator($0)
		}
	}
}

let coreDataDiagnosticsInitializer: Ignored = {
	enableCoreDataAwareErrorDescriptions()
	return Ignored()
}()
