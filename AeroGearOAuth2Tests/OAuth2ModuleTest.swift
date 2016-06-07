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

func setupStubWithNSURLSessionDefaultConfiguration() {
    // set up http stub
    stub({_ in return true}, response: { (request: NSURLRequest!) -> OHHTTPStubsResponse in
            let stubJsonResponse = ["name": "John", "family_name": "Smith"]
            switch request.URL!.path! {
            case "/plus/v1/people/me/openIdConnect":
                let data = try! NSJSONSerialization.dataWithJSONObject(stubJsonResponse, options: NSJSONWritingOptions())
                return OHHTTPStubsResponse(data:data, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/v2.2/me":
                let string = "{\"id\":\"10204448880356292\",\"first_name\":\"Corinne\",\"gender\":\"female\",\"last_name\":\"Krych\",\"link\":\"https:\\/\\/www.facebook.com\\/app_scoped_user_id\\/10204448880356292\\/\",\"locale\":\"en_GB\",\"name\":\"Corinne Krych\",\"timezone\":1,\"updated_time\":\"2014-09-24T10:51:12+0000\",\"verified\":true}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/o/oauth2/token":
                let string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"REFRESH_TOKEN\",\"expires_in\":23}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/o/oauth2/revoke":
                let string = "{}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])

            default: return OHHTTPStubsResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }
        })
}

func setupStubWithNSURLSessionDefaultConfigurationWithoutRefreshTokenIssued() {
    // set up http stub
    stub({_ in return true}, response: { (request: NSURLRequest!) -> OHHTTPStubsResponse in
            switch request.URL!.path! {
            case "/o/oauth2/token":
                let string = "{\"access_token\":\"ACCESS_TOKEN\"}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])

            default: return OHHTTPStubsResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }
        })
}


class OAuth2ModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    func testRequestAccessWithAccessTokenAlreadyStored() {
        let expectation = expectationWithDescription("AccessRequestAlreadyAccessTokenPresent")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let partialMock = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithValidAccessTokenStored())
        partialMock.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("TOKEN" == response as! String, "If access token present and still valid")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRequestAccessWithRefreshFlow() {
        let expectation = expectationWithDescription("AccessRequestwithRefreshFlow")
        let googleConfig = GoogleConfig(
            clientId: "873670803862-g6pjsgt64gvp7r25edgf4154e8sld5nq.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let partialMock = OAuth2ModulePartialMock(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        partialMock.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("NEW_ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRequestAccessWithAuthzCodeFlow() {
        let expectation = expectationWithDescription("AccessRequestWithAuthzFlow")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let partialMock = OAuth2ModulePartialMock(config: googleConfig, session: MockOAuth2SessionWithAuthzCode())
        partialMock.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("ACCESS_TOKEN" == response as! String, "If access token not valid and no refresh token present")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRefreshAccess() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("Refresh")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = OAuth2Module(config: googleConfig, session: mockedSession)
        oauth2Module.refreshAccessToken { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("NEWLY_REFRESHED_ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            XCTAssertTrue("REFRESH_TOKEN" == mockedSession.savedRefreshedToken, "Saved newly issued refresh token")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testExchangeAuthorizationCodeForAccessToken() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("AccessRequest")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let oauth2Module = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        oauth2Module.exchangeAuthorizationCodeForAccessToken ("CODE", completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("NEWLY_REFRESHED_ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testExchangeAuthorizationCodeForAccessTokenwithoutRefreshTokenIssued() {
        setupStubWithNSURLSessionDefaultConfigurationWithoutRefreshTokenIssued()
        let expectation = expectationWithDescription("AccessRequest")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let oauth2Module = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        oauth2Module.exchangeAuthorizationCodeForAccessToken ("CODE", completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRevokeAccess() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("Revoke")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = OAuth2Module(config: googleConfig, session: mockedSession)
        oauth2Module.revokeAccess({(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue(mockedSession.initCalled == 1, "revoke token reset session")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
