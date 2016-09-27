//
//  ItemInListView.swift
//  RSSReader
//
//  Created by Grigory Entin on 27/09/2016.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData

extension Item {
	class func keyPathsForValuesAffectingItemListSectionName() -> Set<String> {
		return [#keyPath(date), #keyPath(loadDate)]
	}
	func itemsListSectionName() -> String {
		let timeInterval = date.timeIntervalSince(date)
		if timeInterval < 24 * 3600 {
			return ""
		}
		else if timeInterval < 7 * 24 * 3600 {
			return "Last Week"
		}
		else if timeInterval < 30 * 7 * 24 * 3600 {
			return "Last Month"
		}
		else if timeInterval < 365 * 7 * 24 * 3600 {
			return "Last Year"
		}
		else {
			return "More than Year Ago"
		}
	}
	func itemListFormattedDate(forNowDate nowDate: Date) -> String {
		let timeInterval = nowDate.timeIntervalSince(self.date)
		return dateComponentsFormatter.string(from: timeInterval)!
	}
}
