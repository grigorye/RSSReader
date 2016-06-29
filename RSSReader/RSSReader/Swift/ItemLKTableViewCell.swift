//
//  ItemLKTableViewCell.swift
//  RSSReader
//
//  Created by Grigory Entin on 29/06/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import RSSReaderData
import GEBase
import LayoutKit
import UIKit

class ItemLKLayout : InsetLayout {
	init(item: Item, nowDate: Date) {
		let layout = StackLayout(
			axis: .horizontal,
			spacing: 4,
			sublayouts: [
				LabelLayout(text: "•"),
				StackLayout(
					axis: .vertical,
					sublayouts: [
						LabelLayout(text: _0 ? "title" : item.title, config: nil),
						StackLayout(
							axis: .horizontal,
							spacing: 4,
							sublayouts: [
								LabelLayout(text: $(_0 ? "author" : item.author)),
								LabelLayout(text: $(item.itemListFormattedDate(forNowDate: nowDate)))
							]
						)
					]
				)
			]
		);
		let insets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
		super.init(insets: insets, sublayout: layout, config: nil)
	}
}

class ItemLKTableViewCellView: UIView {
    private var layout: ItemLKLayout!

    func setData(_ data: (item: Item, container: Container, nowDate: Date)) {
        self.layout = (ItemLKLayout(item: data.item, nowDate: data.nowDate))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return (self.layout.measurement(within: $(size)).size ?? .zero)
    }

    override func intrinsicContentSize() -> CGSize {
        return (sizeThatFits(CGSize(width: .max, height: .max)))
    }

    override func layoutSubviews() {
        let arrangement = self.layout.measurement(within: bounds.size).arrangement(within: bounds)
		(arrangement).makeViews(inView: self)
    }
}

class ItemLKTableViewCell: UITableViewCell, ItemTableViewCellDataBinder {
    lazy var wrappedContentView: ItemLKTableViewCellView = {
		let v = ItemLKTableViewCellView() … {
			$0.translatesAutoresizingMaskIntoConstraints = false
		}
		let contentView = self.contentView
        let views = ["v": v]
        contentView.addSubview(v)
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v]-0-|", options: [], metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v]-0-|", options: [], metrics: nil, views: views))
		return v
    }()
    func setData(_ data: (item: Item, container: Container, nowDate: Date)) {
        self.wrappedContentView.setData(data)
    }
}
