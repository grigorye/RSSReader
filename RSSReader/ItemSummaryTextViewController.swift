//
//  ItemSummaryTextViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 04.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import UIKit

class ItemSummaryTextViewController: UIViewController {
	@IBOutlet var textView: UITextView!
	var item: Item!
    override func viewDidLoad() {
        super.viewDidLoad()
		var loadError: NSError?
		let summaryData = item.summary!.dataUsingEncoding(NSUTF8StringEncoding)!
		let attributedText = NSAttributedString(data: summaryData, options:[NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes:nil, error:&loadError)
		textView.text = attributedText!.string
		self.title = item.title
    }
}
