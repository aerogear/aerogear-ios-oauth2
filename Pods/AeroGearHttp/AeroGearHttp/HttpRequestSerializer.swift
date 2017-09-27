/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

/**
An HttpRequest serializer that handles form-encoded URL requess including multipart support.
*/
open class HttpRequestSerializer:  RequestSerializer {
    /// The url that this request serializer is bound to.
    open var url: URL?
    /// Any headers that will be appended on the request.
    open var headers: [String: String]?
    ///  The cache policy.
    open var cachePolicy: NSURLRequest.CachePolicy
    /// The timeout interval.
    open var timeoutInterval: TimeInterval
    
    /// Defualt initializer.
    public init() {
        self.timeoutInterval = 60
        self.cachePolicy = .useProtocolCachePolicy
    }
    
    /**
    Build an request using the specified params passed in.
    
    :param: url the url of the resource.
    :param: method the method to be used.
    :param: parameters the request parameters.
    :param: headers any headers to be used on this request.
    
    :returns: the URLRequest object.
    */
    open func request(url: URL, method: HttpMethod, parameters: [String: Any]?, headers: [String: String]? = nil) -> URLRequest {
        let request = NSMutableURLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue
        
        // apply headers to new request
        if(headers != nil) {
            for (key,val) in headers! {
                request.addValue(val, forHTTPHeaderField: key)
            }
        }
        
        if method == .get || method == .head || method == .delete {
            let paramSeparator = request.url?.query != nil ? "&" : "?"
            var newUrl:String
            if (request.url?.absoluteString != nil && parameters != nil) {
                let queryString = self.stringFrom(httpParams: parameters!)
                newUrl = "\(request.url!.absoluteString)\(paramSeparator)\(queryString)"
                request.url = URL(string: newUrl)!
            }
            
        } else {
            // set type
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            // set body
            if (parameters != nil) {
                let body = self.stringFrom(httpParams: parameters!).data(using: String.Encoding.utf8)
                request.setValue("\(body?.count)", forHTTPHeaderField: "Content-Length")
                request.httpBody = body
            }
        }
        
        return request as URLRequest
    }
    
    /**
    Build an multipart request using the specified params passed in.
    
    :param: url the url of the resource.
    :param: method the method to be used.
    :param: parameters the request parameters.
    :param: headers  any headers to be used on this request.
    
    :returns: the URLRequest object
    */
    open func multipartRequest(url: URL, method: HttpMethod, parameters: [String: Any]?, headers: [String: String]? = nil) -> URLRequest {
        let request = NSMutableURLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue
        
        // apply headers to new request
        if(headers != nil) {
            for (key,val) in headers! {
                request.addValue(val, forHTTPHeaderField: key)
            }
        }
        
        let boundary = "AG-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = self.multiPartBodyFrom(httpParams: parameters!, boundary: boundary)

        request.setValue(type, forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = body
        
        return request as URLRequest
    }
    
    private func stringFrom(httpParams parameters: [String: Any]) -> String {
        let parametersArray = serialization(httpParams: (nil, parameters)).map({(tuple) in
            return self.stringValue(tuple)
        })
        return parametersArray.joined(separator: "&")
    }
    
    private func serialization(httpParams tuple: (String?, Any)) -> [(String?, Any)] {
        var collect:[(String?, Any)] = []
        if let array = tuple.1 as? [Any] {
            for nestedValue : Any in array {
                let label: String = tuple.0!
                let myTuple:(String?, Any) = (label + "[]", nestedValue)
                collect.append(contentsOf: self.serialization(httpParams: myTuple))
            }
        } else if let dict = tuple.1 as? [String: Any] {
            for (nestedKey, nestedObject) in dict {
                let newKey = tuple.0 != nil ? "\(tuple.0!)[\(nestedKey)]" : nestedKey
                let myTuple:(String?, Any) = (newKey, nestedObject)
                collect.append(contentsOf: self.serialization(httpParams: myTuple))
            }
        } else {
            collect.append((tuple.0, tuple.1))
        }
        return collect
    }
    
    private func stringValue(_ tuple: (String?, Any)) -> String {
        var val = ""
        if let str = tuple.1 as? String {
            val = str
        } else if (tuple.1 as AnyObject).description != nil { //TODO revisit Swift3
            val = (tuple.1 as AnyObject).description
        }
        
        if tuple.0 == nil {
            return val.urlEncode()
        }
        
        return "\(tuple.0!.urlEncode())=\(val.urlEncode())"
    }
    
    private func multiPartBodyFrom(httpParams parameters: [String: Any], boundary: String) -> Data {
        let data = NSMutableData()
        
        let prefixData = "--\(boundary)\r\n".data(using: String.Encoding.utf8)
        let seperData = "\r\n".data(using: String.Encoding.utf8)
        
        for (key, value) in parameters {
            var sectionData: Data?
            var sectionType: String?
            var sectionFilename = ""
            
            if value is MultiPartData {
                let multiData = value as! MultiPartData
                sectionData = multiData.data as Data
                sectionType = multiData.mimeType
                sectionFilename = " filename=\"\(multiData.filename)\""
            } else {
                sectionData = "\(value)".data(using: String.Encoding.utf8)
            }
            
            data.append(prefixData!)
            
            let sectionDisposition = "Content-Disposition: form-data; name=\"\(key)\";\(sectionFilename)\r\n".data(using: String.Encoding.utf8)
            data.append(sectionDisposition!)
            
            if let type = sectionType {
                let contentType = "Content-Type: \(type)\r\n".data(using: String.Encoding.utf8)
                data.append(contentType!)
            }
            
            // append data
            data.append(seperData!)
            data.append(sectionData!)
            data.append(seperData!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        return data as Data
    }
    
    private func hasMultiPartData(httpParams parameters: [String: Any]?) -> Bool {
        if (parameters == nil) {
            return false
        }
        
        var isMultiPart = false
        for (_, value) in parameters! {
            if value is MultiPartData {
                isMultiPart = true
                break
            }
        }
        
        return isMultiPart
    }
}
