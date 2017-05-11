//
//  SummitsRequest.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 11/24/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import Foundation
import AeroGearHttp
import AeroGearOAuth2
import JSON

public extension Store {
    
    func summits(_ page: Int = 1, objectsPerPage: Int = 30, completion: @escaping (ErrorValue<Page<SummitsResponse.Summit>>) -> ()) {
        
        let uri = "/api/v1/summits?page=\(page)&per_page=\(objectsPerPage)"
        
        let http = self.createHTTP(.serviceAccount)
        
        let url = environment.configuration.serverURL + uri
        
        http.request(method: .get, path: url) { (responseObject, error) in
            
            // forward error
            guard error == nil
                else { completion(.error(error!)); return }
            
            guard let json = try? JSON.Value(string: responseObject as! String),
                let response = SummitsResponse(json: json)
                else { completion(.error(Error.invalidResponse)); return }
            
            // success
            completion(.value(response.page))
        }
    }
}

// MARK: - Supporting Types

public struct SummitsResponse: JSONDecodable {
    
    public let page: Page<Summit>
    
    public init?(json: JSON.Value) {
        
        guard let page = Page<Summit>(json: json)
            else { return nil }
        
        self.page = page
    }
}

public extension SummitsResponse {
    
    public struct Summit: JSONDecodable, Named {
        
        public let identifier: Identifier
        
        public let name: String
        
        public let timeZone: TimeZone
        
        public let datesLabel: String?
        
        public let start: Date
        
        public let end: Date
        
        public let active: Bool
        
        public init?(json JSONValue: JSON.Value) {
            
            enum JSONKey: String {
                
                case id, name, start_date, end_date, schedule_start_date, time_zone, dates_label, logo, active, start_showing_venues_date, sponsors, summit_types, ticket_types, event_types, tracks, track_groups, locations, speakers, schedule, timestamp, page_url, wifi_connections
            }
            
            guard let JSONObject = JSONValue.objectValue,
                let identifier = JSONObject[JSONKey.id.rawValue]?.integerValue,
                let name = JSONObject[JSONKey.name.rawValue]?.rawValue as? String,
                let startDate = JSONObject[JSONKey.start_date.rawValue]?.integerValue,
                let endDate = JSONObject[JSONKey.end_date.rawValue]?.integerValue,
                let timeZoneJSON = JSONObject[JSONKey.time_zone.rawValue],
                let timeZone = TimeZone(json: timeZoneJSON),
                let active = JSONObject[JSONKey.active.rawValue]?.rawValue as? Bool
                else { return nil }
            
            self.identifier = identifier
            self.name = name
            self.start = Date(timeIntervalSince1970: TimeInterval(startDate))
            self.end = Date(timeIntervalSince1970: TimeInterval(endDate))
            self.timeZone = timeZone
            self.active = active
            
            self.datesLabel = JSONObject[JSONKey.dates_label.rawValue]?.rawValue as? String
        }
    }
}

public func == (lhs: SummitsResponse.Summit, rhs: SummitsResponse.Summit) -> Bool {
    
    return lhs.identifier == rhs.identifier
        && lhs.name == rhs.name
        && lhs.timeZone == rhs.timeZone
        && lhs.datesLabel == rhs.datesLabel
        && lhs.start == rhs.start
        && lhs.end == rhs.end
        && lhs.active == rhs.active
}
