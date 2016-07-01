//
//  RSSSessionTaskGeneration.swift
//  RSSReaderData
//
//  Created by Grigory Entin on 01/07/16.
//  Copyright © 2016 Grigory Entin. All rights reserved.
//

import GEBase
import Foundation

extension RSSSession {
	typealias TaskCompletionHandler = ProgressEnabledURLSessionTaskGenerator.HTTPDataTaskCompletionHandler
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequestWithURL(_ url: URL, httpMethod: String = "GET", completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		precondition(nil != self.authToken)
		let request = URLRequest(url: url) … {
			$0.httpMethod = httpMethod
			$0.addValue("GoogleLogin auth=\(self.authToken!)", forHTTPHeaderField: "Authorization")
			$0.addValue(self.inoreaderAppID, forHTTPHeaderField: "AppId")
			$0.addValue(self.inoreaderAppKey, forHTTPHeaderField: "AppKey")
		}
		return progressEnabledURLSessionTaskGenerator.dataTask(for: request, completionHandler: completionHandler)
	}
	// MARK: -
	func dataTaskForAuthenticatedHTTPRequest(withPath path: String, httpMethod: String = "GET", completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let url: URL = {
			let components = NSURLComponents() … {
				$0.scheme = "https"
				$0.host = "www.inoreader.com"
				$0.path = path
			}
			return components.url!
		}()
		return self.dataTaskForAuthenticatedHTTPRequestWithURL(url, httpMethod: httpMethod, completionHandler: completionHandler)
	}
	func dataTaskForAuthenticatedHTTPRequest(withRelativeString relativeString: String, httpMethod: String = "GET", completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let baseURL: URL = {
			let components = NSURLComponents() … {
				$0.scheme = "https"
				$0.host = "www.inoreader.com"
				$0.path = "/"
			}
			return components.url!
		}()
		let url = URL(string: relativeString, relativeTo: baseURL)!
		return self.dataTaskForAuthenticatedHTTPRequestWithURL((url), httpMethod: httpMethod, completionHandler: completionHandler)
	}
	// MARK: -
	func dataTaskForPushingTags(for items: Set<Item>, category: Folder, excluded: Bool, completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let urlPath: String = {
			let urlArguments: [String] = {
				assert(0 < items.count)
				let itemIDsComponents = items.map { "i=\($0.shortID)" }
				let command = excluded ? "r" : "a"
				let tag = category.tag()!
				let urlArguments = ["\(command)=\(tag)"] + itemIDsComponents
				return urlArguments
			}()
			let urlArgumentsJoined = urlArguments.joined(separator: "&")
			return "/reader/api/0/edit-tag?\(urlArgumentsJoined)"
		}()
		return self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: urlPath, httpMethod: "POST", completionHandler: completionHandler)
	}
	func dataTaskForAuthentication(completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let url: URL = {
			let components = NSURLComponents() … {
				$0.scheme = "https"
				$0.host = "www.inoreader.com"
				$0.path = "/accounts/ClientLogin"
			}
			return components.url!
		}()
		let request = URLRequest(url: url) … {
			$0.httpMethod = "POST"
			$0.httpBody = {
				let allowedCharacters = NSCharacterSet.alphanumerics()
				let loginEncoded = self.loginAndPassword.login?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
				let passwordEncoded = self.loginAndPassword.password?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
				let body: String = {
					if passwordEncoded == nil && loginEncoded == nil {
						return ""
					}
					return "Email=\(loginEncoded!)&Passwd=\(passwordEncoded!)"
				}()
				return body.data(using: String.Encoding.utf8, allowLossyConversion: false)
			}()
		}
		return progressEnabledURLSessionTaskGenerator.dataTask(for: $(request), completionHandler: completionHandler)
	}
	func dataTaskForStreamContents(_ container: Container, excludedCategory: Folder?, continuation: String?, count: Int, loadDate: Date, completionHandler: TaskCompletionHandler) -> URLSessionDataTask {
		let relativeString: String = {
			let querySuffix = URLQuerySuffixFromComponents([String]() … {
				if let continuation = continuation {
					$0 += ["c=\($(continuation))"]
				}
				if let excludedCategory = excludedCategory {
					$0 += ["xt=\($(excludedCategory.streamID))"]
				}
				$0 += ["n=\(count)"]
			})
			let streamIDPercentEncoded = container.streamID.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics())!
			return "/reader/api/0/stream/contents/\(streamIDPercentEncoded)\(querySuffix)"
		}()
		return self.dataTaskForAuthenticatedHTTPRequest(withRelativeString: relativeString, completionHandler: completionHandler)
	}
}
