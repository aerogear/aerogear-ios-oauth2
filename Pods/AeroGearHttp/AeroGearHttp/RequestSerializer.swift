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
The protocol that request serializers must adhere to.
*/
public protocol RequestSerializer {
    
    /// The url that this request serializer is bound to.
    var url: URL? { get set }
    /// Any headers that will be appended on the request.
    var headers: [String: String]? { get set }
    ///  The cache policy.
    var cachePolicy: NSURLRequest.CachePolicy { get }
    /// The timeout interval.
    var timeoutInterval: TimeInterval { get set }
    
    /**
    Build an request using the specified params passed in.
    
    :param: url the url of the resource.
    :param: method the method to be used.
    :param: parameters the request parameters.
    :param: headers any headers to be used on this request.
    
    :returns: the URLRequest object.
    */
    func request(url: URL, method: HttpMethod, parameters: [String: Any]?, headers: [String: String]?) -> URLRequest
    
    /**
    Build an multipart request using the specified params passed in.
    
    :param: url the url of the resource.
    :param: method the method to be used.
    :param: parameters the request parameters.
    :param: headers any headers to be used on this request.
    
    :returns: the URLRequest object
   */
    func multipartRequest(url: URL, method: HttpMethod, parameters: [String: Any]?, headers: [String: String]?) -> URLRequest
}
