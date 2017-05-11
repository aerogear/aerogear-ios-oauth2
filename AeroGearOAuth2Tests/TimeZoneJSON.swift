//
//  TimeZoneJSON.swift
//  OpenStackSummit
//
//  Created by Alsey Coleman Miller on 6/1/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import JSON

public extension TimeZone {
    
    enum JSONKey: String {
        
        case country_code, latitude, longitude, comments, name, offset
    }
}

extension TimeZone: JSONDecodable {
    
    public init?(json JSONValue: JSON.Value) {
        
        guard let JSONObject = JSONValue.objectValue,
            let countryCode = JSONObject[JSONKey.country_code.rawValue]?.rawValue as? String,
            let latitude = JSONObject[JSONKey.latitude.rawValue]?.rawValue as? Double,
            let longitude = JSONObject[JSONKey.longitude.rawValue]?.rawValue as? Double,
            let comments = JSONObject[JSONKey.comments.rawValue]?.rawValue as? String,
            let name = JSONObject[JSONKey.name.rawValue]?.rawValue as? String,
            let offset = JSONObject[JSONKey.offset.rawValue]?.integerValue
            else { return nil }
        
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.comments = comments
        self.name = name
        self.offset = Int(offset)
    }
}
