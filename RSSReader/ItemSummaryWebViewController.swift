//
//  ItemSummaryWebViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class ItemSummaryWebViewController: UIViewController {
	@IBOutlet var textView: UITextView!
	@IBOutlet var webView: UIWebView!
	var item: Item!
    override func viewDidLoad() {
        super.viewDidLoad()
		self.webView.loadHTMLString(item.summary, baseURL: NSURL(string:"http://localhost"))
		self.title = item.title
    }
}
