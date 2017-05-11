//
//  Named.swift
//  OpenStackSummit
//
//  Created by Alsey Coleman Miller on 5/31/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

/// A named data type.
public protocol Named: Unique {
    
    var name: String { get }
}

public extension Collection where Iterator.Element: Named {
    
    var names: [String] {
        
        return self.map { $0.name }
    }
}
