//
//  RSSSession.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

class RSSSession: NSObject {
	let loginAndPassword: LoginAndPassword
	init(loginAndPassword: LoginAndPassword) {
		self.loginAndPassword = loginAndPassword
	}
	typealias TaskCompletionHandler = ProgressEnabledURLSessionTaskGenerator.HTTPDataTaskCompletionHandler
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithURL(url: NSURL, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask {
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			return $
		}()
		return progressEnabledURLSessionTaskGenerator.dataTaskForHTTPRequest(request, completionHandler: completionHandler)
	}
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithPath(path: String, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: path)!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, completionHandler: completionHandler)
	}
	func dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString: String, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask {
		let url = NSURL(string: relativeString, relativeToURL: NSURL(scheme: "https", host: "www.inoreader.com", path: "/"))!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, completionHandler: completionHandler)
	}
	// MARK: -
	func authenticate(completionHandler: (NSError?) -> Void) {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: "/accounts/ClientLogin")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.HTTPMethod = "POST"
			$.HTTPBody = {
				let allowedCharacters = NSCharacterSet.alphanumericCharacterSet()
				let loginEncoded = self.loginAndPassword.login?.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
				let passwordEncoded = self.loginAndPassword.password?.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
				let body: NSString = {
					if passwordEncoded == nil && loginEncoded == nil {
						return ""
					}
					return "Email=\(loginEncoded!)&Passwd=\(passwordEncoded!)"
				}()
				return body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
			}()
			return $
		}()
		let sessionTask = progressEnabledURLSessionTaskGenerator.dataTaskForHTTPRequest(request) { data, httpResponse, error in
			if let error = error {
				completionHandler(trace("error", error))
				return
			}
			let authToken: String? = {
				let body = NSString(data: data, encoding: NSUTF8StringEncoding)!
				let authLocation = NSMaxRange(body.rangeOfString("Auth="))
				let authRangeMax = body.rangeOfString("\n", options: NSStringCompareOptions(0), range: NSMakeRange(authLocation, body.length - authLocation)).location
				let $ = body.substringWithRange(NSMakeRange(authLocation, authRangeMax - authLocation))
				return $
			}()
			self.authToken = authToken
		}
		sessionTask.resume()
	}
	// MARK: -
	func reauthenticate(completionHandler: (NSError?) -> Void) {
		authenticate(completionHandler)
	}
	// MARK: -
	func updateUserInfo(completionHandler: (NSError?) -> Void) {
		let path = "/reader/api/0/user-info"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let managedObjectContext = self.backgroundQueueManagedObjectContext
			managedObjectContext.performBlock {
				var folders = [Container]()
				let importAndSaveError: NSError? = {
					let importError: NSError? = {
						var jsonParseError: NSError?
						if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &jsonParseError) {
							if let json = jsonObject as? [String : AnyObject] {
								if let userID = json["userId"] as? String {
									let id = "user/\(userID)/\(readTagSuffix)"
									var insertMarkedAsReadFolderError: NSError?
									if let insertedMarkedAsReadFolder = insertedObjectUnlessFetchedWithID(Folder.self, id: id, managedObjectContext: managedObjectContext, error: &insertMarkedAsReadFolderError) {
										return nil
									}
									else {
										return trace("insertMarkedAsReadFolderError", insertMarkedAsReadFolderError)
									}
								}
								else {
									let jsonElementNotFoundOrInvalidError = NSError(domain: GenericCoreDataExtensionsErrorDomain, code: GenericCoreDataExtensionsError.JsonElementNotFoundOrInvalid.rawValue, userInfo: nil)
									return trace("jsonElementNotFoundOrInvalidError", jsonElementNotFoundOrInvalidError)
								}
							}
							else {
								let jsonIsNotDictionaryError = NSError()
								return trace("jsonIsNotDictionaryError", jsonIsNotDictionaryError)
							}
						}
						else {
							return trace("jsonParseError", jsonParseError)
						}
					}()
					if let importError = importError {
						return trace("importError", importError)
					}
					var saveError: NSError?
					if !managedObjectContext.save(&saveError) {
						return trace("saveError", saveError)
					}
					return nil
				}()
				completionHandler(importAndSaveError)
			}
		}
		sessionTask.resume()
	}
	func uploadTag(tag: String, mark: Bool, forItem item: Item, completionHandler: (NSError?) -> Void) {
		let command = mark ? "a" : "r"
		let path = "/reader/api/0/edit-tag?\(command)=\(tag)&i=\(item.itemID)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			completionHandler(error)
		}
		sessionTask.resume()
	}
	func updateUnreadCounts(completionHandler: (NSError?) -> Void) {
		let path = "/reader/api/0/unread-count?output=json"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let managedObjectContext = self.backgroundQueueManagedObjectContext
			managedObjectContext.performBlock {
				var folders = [Container]()
				let importAndSaveError: NSError? = {
					let importError: NSError? = {
						var jsonParseError: NSError?
						if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &jsonParseError) {
							if let json = jsonObject as? [String : AnyObject] {
								if let itemJsons = json["unreadcounts"] as? [[String : AnyObject]] {
									for itemJson in itemJsons {
										let itemID = itemJson["id"] as! String
										let type: Container.Type = itemID.hasPrefix("feed/http") ? Subscription.self : Folder.self
										var importItemError: NSError?
										if let folder = insertedObjectUnlessFetchedWithID(type, id: itemID, managedObjectContext: managedObjectContext, error: &importItemError) {
											folder.importFromUnreadCountJson(itemJson)
											folders += [folder]
										}
										else {
											return trace("importItemError", importItemError)
										}
									}
									return nil
								}
								else {
									let jsonElementNotFoundOrInvalidError = NSError(domain: GenericCoreDataExtensionsErrorDomain, code: GenericCoreDataExtensionsError.JsonElementNotFoundOrInvalid.rawValue, userInfo: nil)
									return trace("jsonElementNotFoundOrInvalidError", jsonElementNotFoundOrInvalidError)
								}
							}
							else {
								let jsonIsNotDictionaryError = NSError()
								return trace("jsonIsNotDictionaryError", jsonIsNotDictionaryError)
							}
						}
						else {
							return trace("jsonParseError", jsonParseError)
						}
					}()
					if let importError = importError {
						return trace("importError", importError)
					}
					var saveError: NSError?
					if !managedObjectContext.save(&saveError) {
						return trace("saveError", saveError)
					}
					return nil
				}()
				completionHandler(importAndSaveError)
			}
		}
		sessionTask.resume()
	}
	func updateTags(completionHandler: (NSError?) -> Void) {
		let path = "/reader/api/0/tag/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				let importAndSaveError: NSError? = {
					var importError: NSError?
					let tags = importItemsFromJsonData(data!, type: Folder.self, elementName: "tags", managedObjectContext: backgroundQueueManagedObjectContext, error: &importError) { (tag, json, error) in
						tag.importFromJson(json)
						return true
					}
					if nil == tags {
						return trace("importError", importError!)
					}
					var saveError: NSError?
					if !backgroundQueueManagedObjectContext.save(&saveError) {
						return trace("saveError", saveError)
					}
					return nil
				}()
				completionHandler(importAndSaveError)
			}
		}
		sessionTask.resume()
	}
	func updateStreamPreferences(completionHandler: (NSError?) -> Void) {
		let path = "/reader/api/0/preference/stream/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let managedObjectContext = self.backgroundQueueManagedObjectContext
			managedObjectContext.performBlock {
				let error: NSError? = {
					var jsonParseError: NSError?
					if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &jsonParseError) {
						if let topLevelJson = jsonObject as? [String : AnyObject] {
							if let streamprefsJson: AnyObject = topLevelJson["streamprefs"] {
								Container.importStreamPreferencesJson(streamprefsJson, managedObjectContext: managedObjectContext)
								var saveError: NSError?
								if !managedObjectContext.save(&saveError) {
									return trace("saveError", saveError)
								}
							}
							return nil
						}
						else {
							let jsonIsNotDictionaryError = NSError()
							return trace("jsonIsNotDictionaryError", jsonIsNotDictionaryError)
						}
					}
					else {
						return trace("jsonParseError", jsonParseError)
					}
				}()
				completionHandler(error)
			}
		}
		sessionTask.resume()
	}
	func updateSubscriptions(completionHandler: (_: NSError?) -> Void) {
		let path = "/reader/api/0/subscription/list"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithPath(path) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				let importAndSaveError: NSError? = {
					var importError: NSError?
					let subscriptions = importItemsFromJsonData(data, type: Subscription.self, elementName: "subscriptions", managedObjectContext: backgroundQueueManagedObjectContext, error: &importError) { (subscription, json, error) in
						subscription.importFromJson(json)
						return true
					}
					if nil == subscriptions {
						return trace("importError", importError!)
					}
					var saveError: NSError?
					if !backgroundQueueManagedObjectContext.save(&saveError) {
						return trace("saveError", saveError)
					}
					return nil
				}()
				completionHandler(importAndSaveError)
			}
		}
		sessionTask.resume()
	}
	func markAllAsRead(container: Container, completionHandler: (NSError?) -> Void) {
		let containerIDPercentEncoded = container.streamID.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
		let newestItemTimestampUsec = container.newestItemDate.timestampUsec
		let relativeString = "/reader/api/0/mark-all-as-read?s=\(containerIDPercentEncoded)&ts=\(newestItemTimestampUsec)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(error)
				return
			}
			let body = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
			assert(body == "OK")
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				let markAsReadHereError: NSError? = {
					var saveError: NSError?
					if !backgroundQueueManagedObjectContext.save(&saveError) {
						return trace("saveError", saveError)
					}
					return nil
				}()
				completionHandler(markAsReadHereError)
			}
		}
		sessionTask.resume()
	}
	// MARK: -
	//
	func updateAllAuthenticated(completionHandler: (NSError?) -> Void) {
		self.updateUserInfo { updateUserInfoError in dispatch_async(dispatch_get_main_queue()) {
			if let updateUserInfoError = trace("updateUserInfoError", updateUserInfoError) {
				presentErrorMessage(NSLocalizedString("Failed to retrieve user info.", comment: ""))
				completionHandler(updateUserInfoError)
				return
			}
			self.updateTags { updateTagsError in dispatch_async(dispatch_get_main_queue()) {
				if let updateTagsError = trace("updateTagsError", updateTagsError) {
					presentErrorMessage(NSLocalizedString("Failed to update tags.", comment: ""))
					completionHandler(updateTagsError)
					return
				}
				self.updateSubscriptions { updateSubscriptionsError in dispatch_async(dispatch_get_main_queue()) {
					if let updateTagsError = trace("updateSubscriptionsError", updateSubscriptionsError) {
						presentErrorMessage(NSLocalizedString("Failed to update subscriptions.", comment: ""))
						completionHandler(updateSubscriptionsError)
						return
					}
					self.updateUnreadCounts { updateUnreadCountsError in dispatch_async(dispatch_get_main_queue()) {
						if let updateUnreadCountsError = trace("updateUnreadCountsError", updateUnreadCountsError) {
							presentErrorMessage(NSLocalizedString("Failed to update unread counts.", comment: ""))
							completionHandler(updateUnreadCountsError)
							return
						}
						self.updateStreamPreferences { updateStreamPreferencesError in dispatch_async(dispatch_get_main_queue()) {
							if let updateStreamPreferencesError = trace("updateUnreadCountsError", trace("updateStreamPreferencesError", updateStreamPreferencesError)) {
								completionHandler(updateStreamPreferencesError)
								return
							}
							completionHandler(nil)
						}}
					}}
				}}
			}}
		}}
	}
	func updateAll(completionHandler: (NSError?) -> Void) {
		let rssSession = Optional(self)
		let postAuthenticate = { () -> Void in
			self.updateAllAuthenticated(completionHandler)
		}
		if (rssSession!.authToken == nil) {
			rssSession!.authenticate { error in dispatch_async(dispatch_get_main_queue()) {
				if let authenticationError = error {
					completionHandler(authenticationError)
				}
				else {
					postAuthenticate()
				}
			}}
		}
		else {
			postAuthenticate()
		}
	}
	// MARK: -
	func streamContents(container: Container, excludedCategory: Folder?, continuation: String?, loadDate: NSDate, completionHandler: (continuation: String?, items: [Item]!, error: NSError?) -> Void) {
		var queryComponents = [String]()
		if let continuation = continuation {
			queryComponents += ["c=\(continuation)"]
		}
		if let excludedCategory = excludedCategory {
			queryComponents += ["xt=\(excludedCategory.streamID)"]
		}
		let subscriptionIDPercentEncoded = container.streamID.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
		let querySuffix = URLQuerySuffixFromComponents(queryComponents)
		let relativeString = "/reader/api/0/stream/contents/\(subscriptionIDPercentEncoded)\(querySuffix)"
		let sessionTask = self.dataTaskForAuthenticatedHTTPRequestWithRelativeString(relativeString) { data, httpResponse, error in
			if let error = error {
				completionHandler(continuation: nil, items: nil, error: error)
				return
			}
			let backgroundQueueManagedObjectContext = self.backgroundQueueManagedObjectContext
			backgroundQueueManagedObjectContext.performBlock {
				let error: NSError? = {
					var jsonParseError: NSError?
					let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &jsonParseError)
					if nil == jsonObject {
						return trace("jsonParseError", jsonParseError!)
					}
					let json = jsonObject! as? [String : AnyObject]
					if nil == json {
						let jsonIsNotDictionaryError = NSError()
						return trace("jsonIsNotDictionaryError", jsonIsNotDictionaryError)
					}
					let continuation = json!["continuation"] as? String
					var importError: NSError?
					let saveEveryItemAfterImport = _0
					let items = importItemsFromJson(json!, type: Item.self, elementName: "items", managedObjectContext: backgroundQueueManagedObjectContext, error: &importError) { (item, itemJson, error) in
						item.importFromJson(itemJson)
						if (_0) {
						item.loadDate = loadDate
						}
						if saveEveryItemAfterImport {
							var saveError: NSError?
							if !backgroundQueueManagedObjectContext.save(&saveError) {
								error.memory = trace("saveError", saveError)
								return false
							}
						}
						return true
					}
					if nil == items {
						return trace("importError", importError!)
					}
					if !saveEveryItemAfterImport {
						var saveError: NSError?
						if !backgroundQueueManagedObjectContext.save(&saveError) {
							return trace("saveError", saveError)
						}
					}
					else {
						assert(!backgroundQueueManagedObjectContext.hasChanges)
					}
					completionHandler(continuation: continuation, items: items, error: nil)
					return nil
				}()
				if let error = error {
					completionHandler(continuation: nil, items: nil, error: error)
				}
			}
		}
		sessionTask.resume()
	}
}