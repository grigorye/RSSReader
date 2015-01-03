//
//  Session.swift
//  RSSReader
//
//  Created by Grigory Entin on 03.01.15.
//  Copyright (c) 2015 Grigory Entin. All rights reserved.
//

import Foundation

let RSSSessionErrorDomain = "com.grigoryentin.RSSReader.RSSSession"

enum RSSSessionError: Int {
	case UnexpectedHTTPResponseStatus
}

class RSSSession : NSObject {
	let loginAndPassword: LoginAndPassword
	let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
	init(loginAndPassword: LoginAndPassword) {
		self.loginAndPassword = loginAndPassword
	}
	func authenticate() {
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
		let sessionTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			if let httpResponse = response as? NSHTTPURLResponse {
				if httpResponse.statusCode == 200 {
					let authToken: NSString? = {
						let body = NSString(data: data, encoding: NSUTF8StringEncoding)!
						let authLocation = NSMaxRange(body.rangeOfString("Auth="))
						let authRangeMax = body.rangeOfString("\n", options: NSStringCompareOptions(0), range: NSMakeRange(authLocation, body.length - authLocation)).location
						let $ = body.substringWithRange(NSMakeRange(authLocation, authRangeMax - authLocation))
						return $
					}()
					self.authToken = authToken
					self.postprocessAuthentication()
				}
			}
			else {
				let body = NSString(data: data, encoding: NSUTF8StringEncoding)
				println("body: \(body)")
			}
		})
		sessionTask.resume()
	}
	func reauthenticate() {
		authenticate()
	}
	func postprocessAuthentication() {
//		self.userInfo()
		self.updateUnreadCounts { (updateUnreadCountsError: NSError?) -> Void in
			void(trace("updateUnreadCountsError", updateUnreadCountsError))
		}
//		self.subscriptions()
//		self.tags()
	}
	func userInfo() {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: "/reader/api/0/user-info")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			return $
		}()
		let sessionTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			println("response: \(response)")
			if let httpResponse = response as? NSHTTPURLResponse {
				if httpResponse.statusCode == 200 {
					var error: NSError?
					let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &error) as NSDictionary?
					println("json: \(json)")
				}
			}
			else {
				let body = NSString(data: data, encoding: NSUTF8StringEncoding)
				println("body: \(body)")
			}
		})
		sessionTask.resume()
	}
	func updateUnreadCounts(completionHandler: (NSError?) -> Void) {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: "/reader/api/0/unread-count?output=json")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			return $
		}()
		let sessionTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			println("response: \(response)")
			let error: NSError? = {
				let httpResponse = response as NSHTTPURLResponse
				if httpResponse.statusCode != 200 {
					return NSError(domain: RSSSessionErrorDomain, code: RSSSessionError.UnexpectedHTTPResponseStatus.rawValue, userInfo: ["httpResponse": httpResponse])
				}
				else {
					var jsonParseError: NSError?
					if let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &jsonParseError) as NSDictionary? {
						if let subscriptionsJsons = json["unreadcounts"] as? Array<NSDictionary> {
							let managedObjectContext = self.backgroundQueueManagedObjectContext
							managedObjectContext.performBlock {
								for json in subscriptionsJsons {
									importJson(Folder.self, json, managedObjectContext: managedObjectContext)
								}
								var saveError: NSError?
								if !managedObjectContext.save(&saveError) {
									trace("saveError", saveError)
								}
								completionHandler(saveError)
							}
						}
						return nil
					}
					else {
						return error
					}
				}
			}()
			if let error = error {
				completionHandler(error)
			}
		})
		sessionTask.resume()
	}
	func tags() {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: "/reader/api/0/tag/list")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			return $
		}()
		let sessionTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			println("response: \(response)")
			if let httpResponse = response as? NSHTTPURLResponse {
				if httpResponse.statusCode == 200 {
					var error: NSError?
					let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &error) as NSDictionary?
					println("json: \(json)")
				}
			}
			else {
				let body = NSString(data: data, encoding: NSUTF8StringEncoding)
				println("body: \(body)")
			}
		})
		sessionTask.resume()
	}
	func updateSubscriptions(completionHandler: (_: NSError?) -> Void) {
		let url = NSURL(scheme: "https", host: "www.inoreader.com", path: "/reader/api/0/subscription/list")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			return $
		}()
		let sessionTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			println("response: \(response)")
			let error: NSError? = {
				let httpResponse = response as NSHTTPURLResponse
				if httpResponse.statusCode != 200 {
					return NSError(domain: RSSSessionErrorDomain, code: RSSSessionError.UnexpectedHTTPResponseStatus.rawValue, userInfo: ["httpResponse": httpResponse])
				}
				else {
					var jsonParseError: NSError?
					if let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &jsonParseError) as NSDictionary? {
						if let subscriptionsJsons = json["subscriptions"] as? Array<NSDictionary> {
							let managedObjectContext = self.backgroundQueueManagedObjectContext
							managedObjectContext.performBlock {
								for json in subscriptionsJsons {
									importJson(Subscription.self, json, managedObjectContext: managedObjectContext)
								}
								var saveError: NSError?
								if !managedObjectContext.save(&saveError) {
									trace("saveError", saveError)
								}
								completionHandler(saveError)
							}
						}
						return nil
					}
					else {
						return error
					}
				}
			}()
			if let error = error {
				completionHandler(error)
			}
		})
		sessionTask.resume()
	}
	func streamContents(subscriptionID: String, continuation: String?, completionHandler: (continuation: NSString?, error: NSError?) -> Void) {
		var queryComponents = [String]()
		if let continuation = continuation {
			queryComponents += ["c=\(continuation)"]
		}
		let url = NSURL(string:"https://www.inoreader.com/reader/api/0/stream/contents/\(subscriptionID)\(URLQuerySuffixFromComponents(queryComponents))")!
		let request: NSURLRequest = {
			let $ = NSMutableURLRequest(URL: url)
			$.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			return $
		}()
		let sessionTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			println("response: \(response)")
			let error: NSError? = {
				let httpResponse = response as NSHTTPURLResponse
				if httpResponse.statusCode != 200 {
					let body = NSString(data: data, encoding: NSUTF8StringEncoding)
					return NSError(domain: RSSSessionErrorDomain, code: RSSSessionError.UnexpectedHTTPResponseStatus.rawValue, userInfo: ["httpResponse": httpResponse, "body": body ?? ""])
				}
				else {
					var jsonParseError: NSError?
					if let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(), error: &jsonParseError) as NSDictionary? {
						let continuation = json["continuation"] as? String
						if let itemsJsons = json["items"] as? Array<NSDictionary> {
							let managedObjectContext = self.backgroundQueueManagedObjectContext
							managedObjectContext.performBlock {
								let error: NSError? = {
									for json in itemsJsons {
										importJson(Item.self, json, managedObjectContext: managedObjectContext)
									}
									var saveError: NSError?
									if !managedObjectContext.save(&saveError) {
										return trace("saveError", saveError)
									}
									return nil
								}()
								if let error = error {
									completionHandler(continuation: nil, error: error)
								}
								else {
									completionHandler(continuation: continuation, error: nil)
								}
							}
						}
						return nil
					}
					else {
						return error
					}
				}
			}()
			if let error = error {
				completionHandler(continuation: nil, error: error)
			}
		})
		sessionTask.resume()
	}
}