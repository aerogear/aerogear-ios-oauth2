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

import UIKit
import XCTest
import AeroGearOAuth2
import AGURLSessionStubs

class OAuth2ModuleTests: XCTestCase {
    
    func http_200(request: NSURLRequest!, params:[String: String]?) -> StubResponse {
        var data: NSData
        if ((params) != nil) {
            data = NSJSONSerialization.dataWithJSONObject(params!, options: nil, error: nil)!
        } else {
            data = NSData.data()
        }
        return StubResponse(data:data, statusCode: 200, headers: ["Content-Type" : "text/json"])
    }
    
    func http_200_response(request: NSURLRequest!) -> StubResponse {
        return http_200(request, params: ["key1":"value1"])
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        StubsManager.removeAllStubs()
    }
    
    func testRequestAccessSucessful() {
        //TODO AGIOS-mock
    }
}