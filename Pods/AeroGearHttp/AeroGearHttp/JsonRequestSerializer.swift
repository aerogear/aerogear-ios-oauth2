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
A request serializer to JSON objects/
*/
open class JsonRequestSerializer:  HttpRequestSerializer {
    /**
    Build an request using the specified params passed in.
    
    :param: url the url of the resource.
    :param: method the method to be used.
    :param: parameters the request parameters.
    :param: headers any headers to be used on this request.
    
    :returns: the URLRequest object.
    */
    open override func request(url: URL, method: HttpMethod, parameters: [String: Any]?, headers: [String: String]? = nil) -> URLRequest {
        if method == .get || method == .head || method == .delete {
            return super.request(url: url, method: method, parameters: parameters, headers: headers)
        } else {
            var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
            request.httpMethod = method.rawValue

            // set type
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // set body
            if (parameters != nil) {
                var body: Data?
                do {
                    body = try JSONSerialization.data(withJSONObject: parameters!, options: [])
                } catch _ {
                    body = nil
                }
                // set body
                if (body != nil) {
                    request.setValue("\(body?.count)", forHTTPHeaderField: "Content-Length")
                    request.httpBody = body
                }
            }
            
            // apply headers to new request
            if(headers != nil) {
                for (key,val) in headers! {
                    request.addValue(val, forHTTPHeaderField: key)
                }
            }

            return request
        }
    }
}
