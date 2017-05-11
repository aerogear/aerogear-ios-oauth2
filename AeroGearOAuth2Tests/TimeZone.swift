//
//  TimeZone.swift
//  OpenStackSummit
//
//  Created by Alsey Coleman Miller on 6/1/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

public struct TimeZone: Equatable {
    
    public var name: String
    
    public var countryCode: String
    
    public var latitude: Double
    
    public var longitude: Double
    
    public var comments: String
        
    public var offset: Int
}

// MARK: - Equatable

public func == (lhs: TimeZone, rhs: TimeZone) -> Bool {
    
    return lhs.name == rhs.name
        && lhs.countryCode == rhs.countryCode
        && lhs.latitude == rhs.latitude
        && lhs.longitude == rhs.longitude
        && lhs.comments == rhs.comments
        && lhs.offset == rhs.offset
}
