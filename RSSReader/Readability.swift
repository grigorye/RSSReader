//
//  Readability.swift
//  RSSReader
//
//  Created by Grigory Entin on 28/11/15.
//  Copyright © 2015 Grigory Entin. All rights reserved.
//

import GEBase
#if DZ_READABILITY_ENABLED
import DZReadability
#endif
import Foundation

func retrieveReadableHTMLFromURL(url: NSURL, completionHandler: (HTMLString: String?, error: ErrorType?) -> ()) {
	let completeWithError: (ErrorType) -> () = { error in
		completionHandler(HTMLString: nil, error: error)
	}
	let dataTask = progressEnabledURLSessionTaskGenerator.textTaskForHTTPRequest(NSURLRequest(URL: url)) { text, error in
		guard let HTMLString = text where nil == error else {
			completeWithError($(error!))
			return
		}
#if !DZ_READABILITY_ENABLED
		completionHandler(HTMLString: HTMLString, error: nil)
#else
		dispatch_async(dispatch_get_main_queue()) {
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
