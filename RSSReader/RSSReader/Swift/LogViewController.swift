//
//  LogViewController.swift
//  RSSReader
//
//  Created by Grigory Entin on 08.09.16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderAppConfig
import GEBase
import UIKit.UIViewController

class LogViewController: UIViewController {
	@IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

		guard let data = try? Data(contentsOf: logFileURL, options: .mappedIfSafe) else { return }
		webView.load(data, mimeType: "text/plain", textEncodingName: "UTF-8", baseURL: URL(fileURLWithPath: "/"))
    }
}
