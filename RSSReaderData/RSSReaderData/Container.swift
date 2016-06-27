//
//  Container.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 08.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import GEBase
import CoreData

public class Container : NSManagedObject {
    @NSManaged public var streamID: String
    @NSManaged public var unreadCount: Int32
    @NSManaged var newestItemDate: Date
    @NSManaged var sortID: Int32
	@NSManaged public var parentFolder: Folder?
	@NSManaged public var viewStates: Set<ContainerViewState>
}

@objc public protocol Titled {
	var visibleTitle: String? { get }
}

@objc public protocol ItemsOwner {
	var ownItems: Set<Item> { get }
}

extension Container : DefaultSortable {
	public class func defaultSortDescriptor() -> SortDescriptor {
		return SortDescriptor(key: #keyPath(streamID), ascending: true)
	}
}

extension Container: ManagedIdentifiable {
	public class func identifierKey() -> String {
		return #keyPath(streamID)
	}
	public class func entityName() -> String {
		return "Container"
	}
}

extension Container {
	func importFromJson(_ jsonObject: AnyObject) throws {
		let sortID: Int32 = try {
			guard let json = jsonObject as? [String: AnyObject] else {
				throw JsonImportError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
			}
			guard let sortIDString = (json)["sortid"] as? String else {
				throw JsonImportError.MissingSortID(json: json)
			}
			var sortIDUnsigned : UInt32 = 0
			guard Scanner(string: sortIDString).scanHexInt32(&sortIDUnsigned) else {
				throw JsonImportError.SortIDIsNotHex(json: json)
			}
			let sortID = Int32(bitPattern: sortIDUnsigned)
			return (sortID)
		}()
		if self.sortID != sortID {
			self.sortID = sortID
		}
	}
	func importFromUnreadCountJson(_ jsonObject: AnyObject) {
		let json = jsonObject as! [String: AnyObject]
		self.streamID = {
			let streamID = json["id"] as! String
			return (streamID)
		}()
		self.unreadCount = (json["count"] as? NSString)?.intValue ?? (json["count"] as! NSNumber).int32Value
		self.newestItemDate = Date(timestampUsec: json["newestItemTimestampUsec"] as! String)
	}
	class func importStreamPreferencesJson(_ jsonObject: AnyObject, managedObjectContext: NSManagedObjectContext) throws {
		guard let json = jsonObject as? [String : [[String : AnyObject]]] else {
			throw JsonImportError.JsonObjectIsNotDictionary(jsonObject: jsonObject)
		}
		for (folderID, prefs) in json {
			•(folderID)
			•(prefs)
			for prefs in prefs {
				guard let id = prefs["id"] as? String else {
					throw JsonImportError.MissingPrefsID(json: prefs)
				}
				if id != "subscription-ordering" {
					continue
				}
				guard let value = prefs["value"] as? String else {
					throw JsonImportError.PrefsMissingValue(prefs: prefs)
				}
				•(value)
				let folder = try insertedObjectUnlessFetchedWithID(Folder.self, id: folderID, managedObjectContext: managedObjectContext)
				assert(folder.streamID == folderID)
				let characterCountInValue = value.characters.count
				guard characterCountInValue % 8 == 0 else {
					throw JsonImportError.PrefsValueLengthIsNotFactorOf8(prefs: prefs)
				}
				var sortIDs = [Int32]()
				var sliceIndex = value.startIndex
				while sliceIndex != value.endIndex {
					let nextSliceIndex = value.index(sliceIndex, offsetBy: 8)
					let range = sliceIndex..<nextSliceIndex
					let sortIDString = value[range]
					var sortIDUnsigned : UInt32 = 0
					guard Scanner(string: sortIDString).scanHexInt32(&sortIDUnsigned) else {
						throw JsonImportError.SortIDInPrefsValueIsNotHex(prefs: prefs, value: value)
					}
					let sortID = Int32(bitPattern: sortIDUnsigned)
					sortIDs += [sortID]
					sliceIndex = nextSliceIndex
				}
				typealias E = Container
				let request = E.fetchRequestForEntity() … {
					$0.predicate = Predicate(format: "\(#keyPath(E.sortID)) IN %@", argumentArray: [sortIDs.map { NSNumber(value: $0) }])
				}
				let unorderedChildContainers = try managedObjectContext.fetch(request)
				•(unorderedChildContainers)
				let childContainers = sortIDs.map { sortID in
					return unorderedChildContainers.filter { $0.sortID == sortID }.onlyElement!
				}
				folder.childContainers = OrderedSet(array: childContainers)
			}
		}
	}
}
