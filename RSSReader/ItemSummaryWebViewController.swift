//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var webView: UIWebView!
	var item: Item!
	override func viewDidLoad() {
		super.viewDidLoad()
		let bundle = NSBundle.mainBundle()
		let htmlTemplateURL = bundle.URLForResource("ItemSummaryTemplate", withExtension: "html")!
		var htmlTemplateLoadError: NSError?
		let htmlTemplate = NSString(contentsOfURL: htmlTemplateURL, encoding: NSUTF8StringEncoding, error: &htmlTemplateLoadError)!
		let htmlString =
			htmlTemplate
				.stringByReplacingOccurrencesOfString("$$Summary$$", withString: item.summary!)
				.stringByReplacingOccurrencesOfString("$$Title$$", withString: item.title!)
		self.webView.loadHTMLString(htmlString, baseURL: bundle.resourceURL)
	}
}
