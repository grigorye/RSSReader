//
//  Folder.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 02.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import CoreData

public class Folder : Container {
	typealias _Self = Folder
	@NSManaged public var childContainers: OrderedSet
	@NSManaged var items: Set<Item>
	@NSManaged var itemsToBeExcluded: Set<Item>
	@NSManaged var itemsToBeIncluded: Set<Item>
}

func tagFromStreamID(_ streamID: String) -> String? {
	var components = streamID.components(separatedBy: "/")
	guard components[0] == "user" else {
		return nil
	}
	components[1] = "-"
	let tag = components.joined(separator: "/")
	return tag
}

extension Folder {
	final func items(toBeExcluded excluded: Bool) -> Set<Item> {
		if excluded {
			return itemsToBeExcluded
		}
		else {
			return itemsToBeIncluded
		}
	}
	final func tag() -> String? {
		return tagFromStreamID(streamID)
	}
}

extension Folder : Titled {
	final public var visibleTitle: String? {
		return (streamID as NSString).lastPathComponent
	}
}

extension Folder : ItemsOwner {
	public var ownItems: Set<Item> {
		return self.items
	}
}
