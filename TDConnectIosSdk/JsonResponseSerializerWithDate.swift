//
//  JsonResponseSerializerWithDate.swift
//  Pods
//
//  Created by Jørund Fagerjord on 15/03/18.
//
//

import Foundation
import AeroGearHttp

open class JsonResponseSerializerWithDate: JsonResponseSerializer {
    
    let dateFormatter = DateFormatter()
    
    open var lastServerTime: Date?
    
    public override init() {
        super.init()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        let superValidation = self.validation
        self.validation = { (response: URLResponse?, data: Data) throws -> Void in
            try superValidation(response, data)
            let httpResponse = response as! HTTPURLResponse
            guard let serverDate = httpResponse.allHeaderFields["Date"] as? String else {
                return
            }
            self.lastServerTime = self.dateFormatter.date(from: serverDate)
        }
    }
    
}
