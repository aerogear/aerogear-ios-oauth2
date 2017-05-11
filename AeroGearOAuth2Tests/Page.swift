//
//  Page.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 10/3/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import Foundation

/// Used for fetching requests that require paging.
public struct Page<Item> {
    
    public let currentPage: Int
    
    public let total: Int
    
    public let lastPage: Int
    
    public let perPage: Int
    
    public let items: [Item]
    
    public static var empty: Page<Item> {
        
        return Page(currentPage: 1, total: 1, lastPage: 1, perPage: 0, items: [])
    }
}
