//
//  WeakObject.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 09/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import Foundation

// Borrowed from WeakObject at https://stackoverflow.com/a/36184182

class WeakRefernece<T: AnyObject>: Equatable, Hashable {
    
    weak var object: T?
    
    init(object: T) {
        
        self.object = object
    }
    
    var hashValue: Int {
        
        guard var object = object else {
            return 0
        }
        
        return UnsafeMutablePointer<T>(&object).hashValue
    }
    
    static func == (lhs: WeakRefernece<T>, rhs: WeakRefernece<T>) -> Bool {
        
        return lhs.object === rhs.object
    }
}
