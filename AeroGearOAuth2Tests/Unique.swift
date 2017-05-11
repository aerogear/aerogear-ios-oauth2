//
//  Unique.swift
//  OpenStackSummit
//
//  Created by Alsey Coleman Miller on 5/31/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

/// A data type that can be uniquely identified.
public protocol Unique: Equatable, Hashable, Comparable {
    
    var identifier: Identifier { get }
}

public typealias Identifier = Int64

// MARK: - Hashable

public extension Unique {
    
    var hashValue: Int {
        
        return Int(identifier)
    }
}

// MARK: - Comparable

public func < <T: Unique> (lhs: T, rhs: T) -> Bool {
    
    return lhs.identifier < rhs.identifier
}

// MARK: - Extensions

public extension Collection where Iterator.Element: Unique {
    
    var identifiers: [Identifier] {
        
        return self.map { $0.identifier }
    }
    
    @inline(__always)
    func with(_ identifier: Identifier) -> Self.Iterator.Element? {
        
        return self.first(where: { $0.identifier == identifier })
    }
}
