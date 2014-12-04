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
import AeroGearHttp
import AGURLSessionStubs

class OAuth2ModuleTests: XCTestCase {
    var stubJsonResponse = ["name": "John", "family_name": "Smith"]
    
    func http_200(request: NSURLRequest!, params:[String: String]?) -> StubResponse {
        var data: NSData
        data = NSJSONSerialization.dataWithJSONObject(stubJsonResponse, options: nil, error: nil)!

        return StubResponse(data:data, statusCode: 200, headers: ["Content-Type" : "text/json"])
    }
    
    func http_200_response_john_smith(request: NSURLRequest!) -> StubResponse {
        return http_200(request, params: ["access_token": "TOKEN"])
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
    class MyMockHttp: Http {
    }
    
    class MyMockOAuth2Module: OAuth2Module {
       
        override func requestAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
            var accessToken: AnyObject? = NSString(string:"TOKEN")
            completionHandler(accessToken, nil)
        }
    }
    
    func testOpenID() {
        let loginExpectation = expectationWithDescription("Login");

        let googleConfig = GoogleConfig(
            clientId: "302356789040-eums187utfllgetv6kmbems0pm3mfhgl.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"],
            isOpenIDConnect: true)
        
        // set up http stub
        StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
            return true
            }, withStubResponse:( self.http_200_response_john_smith ))
        
        var oauth2Module = AccountManager.addAccount(googleConfig, moduleClass: MyMockOAuth2Module.self)
        
        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIDClaim?, error: NSError?) in

            XCTAssertTrue(self.stubJsonResponse["name"] == claims?.name, "claim shoud be as mocked")
            loginExpectation.fulfill()
            
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

}