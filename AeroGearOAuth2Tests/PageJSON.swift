//
//  ListJSON.swift
//  OpenStack Summit
//
//  Created by Alsey Coleman Miller on 10/3/16.
//  Copyright © 2016 OpenStack. All rights reserved.
//

import JSON

enum PageJSONKey: String {
    
    case current_page, total, last_page, data, per_page
}

public extension Page where Item: JSONDecodable {
    
    public init?(json JSONValue: JSON.Value) {
        
        guard let JSONObject = JSONValue.objectValue,
            let currentPage = JSONObject[PageJSONKey.current_page.rawValue]?.integerValue,
            let total = JSONObject[PageJSONKey.total.rawValue]?.integerValue,
            let lastPage = JSONObject[PageJSONKey.last_page.rawValue]?.integerValue,
            let perPage = JSONObject[PageJSONKey.per_page.rawValue]?.integerValue,
            let dataArray = JSONObject[PageJSONKey.data.rawValue]?.arrayValue,
            let items = Item.from(json: dataArray)
            else { return nil }
        
        self.currentPage = Int(currentPage)
        self.total = Int(total)
        self.lastPage = Int(lastPage)
        self.perPage = Int(perPage)
        self.items = items
    }
}
