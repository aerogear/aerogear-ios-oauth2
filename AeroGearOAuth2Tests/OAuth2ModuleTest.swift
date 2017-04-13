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
@testable import AeroGearOAuth2
import AeroGearHttp
import OHHTTPStubs

public func stub(condition: @escaping OHHTTPStubsTestBlock, response: @escaping OHHTTPStubsResponseBlock) -> OHHTTPStubsDescriptor {
    return OHHTTPStubs.stubRequests(passingTest: condition, withStubResponse: response)
}

func setupStubWithNSURLSessionDefaultConfiguration() {
    // set up http stub
    _ = stub(condition: {_ in return true}, response: { (request: URLRequest!) -> OHHTTPStubsResponse in
            let stubJsonResponse = ["name": "John", "family_name": "Smith"]
            switch request.url!.path {
            case "/plus/v1/people/me/openIdConnect":
                let data = try! JSONSerialization.data(withJSONObject: stubJsonResponse, options: JSONSerialization.WritingOptions())
                return OHHTTPStubsResponse(data:data, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/v2.2/me":
                let string = "{\"id\":\"10204448880356292\",\"first_name\":\"Corinne\",\"gender\":\"female\",\"last_name\":\"Krych\",\"link\":\"https:\\/\\/www.facebook.com\\/app_scoped_user_id\\/10204448880356292\\/\",\"locale\":\"en_GB\",\"name\":\"Corinne Krych\",\"timezone\":1,\"updated_time\":\"2014-09-24T10:51:12+0000\",\"verified\":true}"
                let data = string.data(using: String.Encoding.utf8)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/o/oauth2/token":
                let string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"REFRESH_TOKEN\",\"expires_in\":23}"
                let data = string.data(using: String.Encoding.utf8)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/o/oauth2/revoke":
                let string = "{}"
                let data = string.data(using: String.Encoding.utf8)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])

            default: return OHHTTPStubsResponse(data:Data(), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }
        })
}

func setupStubWithNSURLSessionDefaultConfigurationWithoutRefreshTokenIssued() {
    // set up http stub
    _ = stub(condition: {_ in return true}, response: { (request: URLRequest!) -> OHHTTPStubsResponse in
            switch request.url!.path {
            case "/o/oauth2/token":
                let string = "{\"access_token\":\"ACCESS_TOKEN\"}"
                let data = string.data(using: String.Encoding.utf8)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])

            default: return OHHTTPStubsResponse(data:Data(), statusCode: 200, headers: ["Content-Type" : "text/json"])
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
        let expectation = self.expectation(description: "AccessRequestAlreadyAccessTokenPresent")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let partialMock = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithValidAccessTokenStored())
        partialMock.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("TOKEN" == response as! String, "If access token present and still valid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testRequestAccessWithRefreshFlow() {
        let expectation = self.expectation(description: "AccessRequestwithRefreshFlow")
        let googleConfig = GoogleConfig(
            clientId: "873670803862-g6pjsgt64gvp7r25edgf4154e8sld5nq.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let partialMock = OAuth2ModulePartialMock(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        partialMock.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("NEW_ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testRequestAccessWithAuthzCodeFlow() {
        let expectation = self.expectation(description: "AccessRequestWithAuthzFlow")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let partialMock = OAuth2ModulePartialMock(config: googleConfig, session: MockOAuth2SessionWithAuthzCode())
        partialMock.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("ACCESS_TOKEN" == response as! String, "If access token not valid and no refresh token present")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testRefreshAccess() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = self.expectation(description: "Refresh")
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
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testExchangeAuthorizationCodeForAccessToken() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = self.expectation(description: "AccessRequest")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let oauth2Module = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        oauth2Module.exchangeAuthorizationCodeForAccessToken (code: "CODE", completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("NEWLY_REFRESHED_ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testExchangeAuthorizationCodeForAccessTokenwithoutRefreshTokenIssued() {
        setupStubWithNSURLSessionDefaultConfigurationWithoutRefreshTokenIssued()
        let expectation = self.expectation(description: "AccessRequest")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let oauth2Module = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        oauth2Module.exchangeAuthorizationCodeForAccessToken (code: "CODE", completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue("ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testRevokeAccess() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = self.expectation(description: "Revoke")
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = OAuth2Module(config: googleConfig, session: mockedSession)
        oauth2Module.revokeAccess(completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            XCTAssertTrue(mockedSession.initCalled == 1, "revoke token reset session")
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGoogleURLParams() {
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"],
            audienceId: "xxx2.apps.googleusercontent.com"
        )
        googleConfig.isWebView = true

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = OAuth2Module(config: googleConfig, session: mockedSession)
        oauth2Module.requestAuthorizationCode { (response: AnyObject?, error:NSError?) -> Void in
            // noop
        }

        let urlString = oauth2Module.webView!.targetURL.absoluteString
        XCTAssertNotNil(urlString.range(of: "audience"), "If URL string doesn't contain an audience field")
    }
}
