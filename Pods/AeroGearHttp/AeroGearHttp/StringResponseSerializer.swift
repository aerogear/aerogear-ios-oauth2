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
A response deserializer to a generic String object.
*/
open class StringResponseSerializer : ResponseSerializer {
    /**
    Deserialize the response received.
    
    :returns: the serialized response
    */
    open var response: (Data, Int) -> Any? = {(data: Data, status: Int) -> (Any?) in
        return NSString(data: data, encoding:String.Encoding.utf8.rawValue)
    }
    
    /**
    Validate the response received.
    
    :returns:  either true or false if the response is valid for this particular serializer.
    */
    open var validation: (URLResponse?, Data) throws -> Void = { (response: URLResponse?, data: Data) throws in
        var error: NSError! = NSError(domain: HttpErrorDomain, code: 0, userInfo: nil)
        let httpResponse = response as! HTTPURLResponse
        
        if !(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
            let userInfo = [
                NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                NetworkingOperationFailingURLResponseErrorKey: response ?? "HttpErrorDomain"] as [String : Any]
            error = NSError(domain: HttpResponseSerializationErrorDomain, code: httpResponse.statusCode, userInfo: userInfo)
            throw error
        }
    } 
    
    public init() {
    }
    
    public init(validation: @escaping (URLResponse?, Data) throws -> Void, response: @escaping (Data, Int) -> AnyObject?) {
        self.validation = validation
        self.response = response
    }
    
    public init(validation: @escaping (URLResponse?, Data) throws -> Void) {
        self.validation = validation
    }
    
    public init(response: @escaping (Data, Int) -> AnyObject?) {
        self.response = response
    }
}
