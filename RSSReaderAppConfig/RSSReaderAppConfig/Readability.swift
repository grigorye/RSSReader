//
//  Readability.swift
//  RSSReader
//
//  Created by Grigory Entin on 28/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEFoundation
import GEBase
#if DZ_READABILITY_ENABLED
import DZReadability
#endif
import Foundation

public func retrieveReadableHTMLFromURL(_ url: URL, completionHandler: @escaping ((HTMLString: String?, error: Error?)) -> ()) {
	let completeWithError: (Error) -> () = { error in
		completionHandler((HTMLString: nil, error: error))
	}
	let dataTask = progressEnabledURLSessionTaskGenerator.textTask(for: URLRequest(url: url)) { text, error in
		guard let HTMLString = text, nil == error else {
			completeWithError($(error!))
			return
		}
#if !DZ_READABILITY_ENABLED
		completionHandler((HTMLString: HTMLString, error: nil))
#else
		DispatchQueue.main.async {
			let readability = DZReadability(URL: url, rawDocumentContent: text, options: nil) { sender, content, error in
				if let error = error {
					completeWithError($(error))
					return
				}
				completionHandler(HTMLString: content, error: nil)
			}
			readability.start()
		}
#endif
	}!
	dataTask.resume()
}
