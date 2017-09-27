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
Error domain for serializers.
*/
public let HttpResponseSerializationErrorDomain = "ResponseSerializerDomain"

/**
The protocol that response serializers must adhere to.
*/
public protocol ResponseSerializer {
    
    /**
     Deserialize the response received.

     :returns: the serialized response
    */
    var response: (Data, Int) -> Any? {get set}
    
    /**
     Validate the response received. This is a cutomizable closure variable.
    
     :returns:  either true or false if the response is valid for this particular serializer.
    */
    var validation: (URLResponse?, Data) throws -> Void {get set}
}
