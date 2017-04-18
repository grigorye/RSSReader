//
//  CwlCancellable.swift
//  CwlUtils
//
//  Created by Matt Gallagher on 2017/04/18.
//  Copyright © 2017 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

/// This protocol exists to provide lifetime to asynchronous an ongoing tasks. Typically, this protocol is implemented by a `class` (so that releasing the type releases the underlying resource) but it may also be implemented by a `struct` which itself contains a `class` whose lifetime controls the underlying resource.
///
/// The pattern offered by this protocol is a rejection of patterns where an asynchronous or ongoing task is created without returning any lifetime object. In my opinion, such lifetime-less patterns are problematic since they fail to tie the lifetime of the asynchronous task to the context where the result is required. This failure to tie task to result context requires:
///	* vigilance to remember to check for the context on completion
///   * knowledge of the context to check if the task is still relevant
///   * overuse of resources by cancelled or unwanted tasks that continue to completion before checking if they're still needed
/// all of which are bad. Far better to return a lifetime object for *all* asynchronous or ongoing tasks.
public protocol Cancellable: class {
	/// Immediately cancel
	func cancel()
}

/// A simple class for aggregating a number of Cancellable instances into a single Cancellable.
public class ArrayOfCancellables: Cancellable {
	public init(cancellables: [Cancellable]) {
		self.cancellables = cancellables
	}
	private let cancellables: [Cancellable]
	public func cancel() { cancellables.forEach { $0.cancel() } }
}

