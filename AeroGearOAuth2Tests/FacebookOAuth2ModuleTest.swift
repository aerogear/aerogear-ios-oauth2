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
import OHHTTPStubs

func setupStubFacebookWithNSURLSessionDefaultConfiguration() {
    // set up http stub
    stub({_ in return true}, response: { (request: NSURLRequest!) -> OHHTTPStubsResponse in
            _ = ["name": "John", "family_name": "Smith"]
            switch request.URL!.path! {
            case "/me/permissions":
                let string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"nnn\",\"expires_in\":23}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/oauth/access_token":
                let string = "access_token=CAAK4k&expires=5183999"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/plain"])
            default: return OHHTTPStubsResponse(data:NSData(), statusCode: 404, headers: ["Content-Type" : "text/json"])
            }
        })
}

class FacebookOAuth2ModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupStubFacebookWithNSURLSessionDefaultConfiguration()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    func testExchangeAuthorizationCodeForAccessToken() {
        let expectation = expectationWithDescription("ExchangeAccessToken")
        let facebookConfig = FacebookConfig(
            clientId: "xxx",
            clientSecret: "yyy",
            scopes:["photo_upload, publish_actions"])

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = FacebookOAuth2Module(config: facebookConfig, session: mockedSession, requestSerializer: JsonRequestSerializer(), responseSerializer: StringResponseSerializer())
        oauth2Module.exchangeAuthorizationCodeForAccessToken("CODE", completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue(response as! String == "CAAK4k", "Check access token is return to callback")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRevokeAccess() {
        let expectation = expectationWithDescription("Revoke")
        let facebookConfig = FacebookConfig(
            clientId: "xxx",
            clientSecret: "yyy",
            scopes:["photo_upload, publish_actions"])

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = FacebookOAuth2Module(config: facebookConfig, session: mockedSession, requestSerializer: JsonRequestSerializer(), responseSerializer: StringResponseSerializer())
        oauth2Module.revokeAccess({(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue(mockedSession.initCalled == 1, "revoke token reset session")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

}
