//
//  LoggyExtensions.swift
//  RSSReader
//
//  Created by Grigory Entin on 12/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Loggy
import Dispatch

extension Activity {
	
	typealias DoneHandler = () -> Void
	
	func execute(on bodyQueue: DispatchQueue = .main, _ body: @escaping (@escaping DoneHandler) -> Void) {
		let group = DispatchGroup()
		let awaitingQueue = DispatchQueue.global()
		group.enter()
		awaitingQueue.async {
			self.execute {
				bodyQueue.async {
					body({
						group.leave()
					})
				}
			}
			group.wait()
		}
	}
}
