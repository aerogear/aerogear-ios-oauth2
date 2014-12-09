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

func setupStubWithNSURLSessionDefaultConfiguration() {
    // set up http stub
    StubsManager.stubRequestsPassingTest({ (request: NSURLRequest!) -> Bool in
        return true
        }, withStubResponse:( { (request: NSURLRequest!) -> StubResponse in
            var stubJsonResponse = ["name": "John", "family_name": "Smith"]
            switch request.URL.path! {
            case "/plus/v1/people/me/openIdConnect":
                var data: NSData
                data = NSJSONSerialization.dataWithJSONObject(stubJsonResponse, options: nil, error: nil)!
                return StubResponse(data:data, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/v2.2/me":
                var string = "{\"id\":\"10204448880356292\",\"first_name\":\"Corinne\",\"gender\":\"female\",\"last_name\":\"Krych\",\"link\":\"https:\\/\\/www.facebook.com\\/app_scoped_user_id\\/10204448880356292\\/\",\"locale\":\"en_GB\",\"name\":\"Corinne Krych\",\"timezone\":1,\"updated_time\":\"2014-09-24T10:51:12+0000\",\"verified\":true}"
                var data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return StubResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/o/oauth2/token":
                var string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"REFRESH_TOKEN\",\"expires_in\":23}"
                var data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return StubResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/auth/realms/shoot-realm/tokens/refresh":
                var string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"eyJhbGciOiJSUzI1NiJ9.eyJuYW1lIjoiU2FtcGxlIFVzZXIiLCJlbWFpbCI6InNhbXBsZS11c2VyQGV4YW1wbGUiLCJqdGkiOiI5MTEwNjAwZS1mYTdiLTRmOWItOWEwOC0xZGJlMGY1YTY5YzEiLCJleHAiOjE0MTc2ODg1OTgsIm5iZiI6MCwiaWF0IjoxNDE3Njg4Mjk4LCJpc3MiOiJzaG9vdC1yZWFsbSIsImF1ZCI6InNob290LXJlYWxtIiwic3ViIjoiNzJhN2Q0NGYtZDcxNy00MDk3LWExMWYtN2FhOWIyMmM5ZmU3IiwiYXpwIjoic2hhcmVkc2hvb3QtdGhpcmQtcGFydHkiLCJnaXZlbl9uYW1lIjoiU2FtcGxlIiwiZmFtaWx5X25hbWUiOiJVc2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlciIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwic2Vzc2lvbl9zdGF0ZSI6Ijg4MTJlN2U2LWQ1ZGYtNDc4Yi1iNDcyLTNlYWU5YTI2ZDdhYSIsImFsbG93ZWQtb3JpZ2lucyI6W10sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJ1c2VyIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnt9fQ.ZcNu8C4yeo1ALqnLvEOK3NxnaKm2BR818B4FfqN3WQd3sc6jvtGmTPB1C0MxF6ku_ELVs2l_HJMjNdPT9daUoau5LkdCjSiTwS5KA-18M5AUjzZnVo044-jHr_JsjNrYEfKmJXX0A_Zdly7el2tC1uPjGoeBqLgW9GowRl3i4wE\",\"expires_in\":23}"
                var data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return StubResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            default: return StubResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }
        }))
}

public class MockOAuth2SessionWithValidAccessTokenStored: OAuth2Session {
    public var accountId: String {
        get {
            return "account"
        }
    }
    public var accessToken: String? {
        get {
            return "TOKEN"
        }
        set(data) {}
    }
    public var accessTokenExpirationDate: NSDate?
    public var refreshTokenExpirationDate: NSDate?
    public var refreshToken: String?
    public func tokenIsNotExpired() -> Bool {
        return true
    }
    
    public func refreshTokenIsNotExpired() -> Bool {
        return true
    }
    
    public func saveAccessToken() {}
    
    public func saveAccessToken(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?) {}
    public init() {}
}

public class MockOAuth2SessionWithRefreshToken: MockOAuth2SessionWithValidAccessTokenStored {
    public var savedRefreshedToken: String?
    public var initCalled = 0
    public override var refreshToken: String? {
        get {
            return "REFRESH_TOKEN"
        }
        set(data) {}
    }
    public override func tokenIsNotExpired() -> Bool {
        return false
    }
    public override func saveAccessToken(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?) {
        savedRefreshedToken = refreshToken
    }
    public override func saveAccessToken() {initCalled = 1}
    public override init() {}
}

public class MockOAuth2SessionWithAuthzCode: MockOAuth2SessionWithValidAccessTokenStored {
    public override var refreshToken: String? {
        get {
            return nil
        }
        set(data) {}
    }
    public override func tokenIsNotExpired() -> Bool {
        return false
    }
    
}

class OAuth2ModulePartialMock: OAuth2Module {
    override func refreshAccessToken(completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler("NEW_ACCESS_TOKEN", nil)
    }
    override func requestAuthorizationCode(completionHandler: (AnyObject?, NSError?) -> Void) {
        completionHandler("ACCESS_TOKEN", nil)
    }
}

class OAuth2ModuleTests: XCTestCase {
   
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        StubsManager.removeAllStubs()
    }
    
    func testRequestAccessWithAccessTokenAlreadyStored() {
        let expectation = expectationWithDescription("AccessRequestAlreadyAccessTokenPresent");
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])
        
        var partialMock = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithValidAccessTokenStored())
        partialMock.requestAccess { (response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue("TOKEN" == response as String, "If access token present and still valid")
            expectation.fulfill()            
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRequestAccessWithRefreshFlow() {
        let expectation = expectationWithDescription("AccessRequestwithRefreshFlow");
        let googleConfig = GoogleConfig(
            clientId: "873670803862-g6pjsgt64gvp7r25edgf4154e8sld5nq.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])
        
        var partialMock = OAuth2ModulePartialMock(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        partialMock.requestAccess { (response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue("NEW_ACCESS_TOKEN" == response as String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRequestAccessWithAuthzCodeFlow() {
        let expectation = expectationWithDescription("AccessRequestWithAuthzFlow");
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])
        
        var partialMock = OAuth2ModulePartialMock(config: googleConfig, session: MockOAuth2SessionWithAuthzCode())
        partialMock.requestAccess { (response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue("ACCESS_TOKEN" == response as String, "If access token not valid and no refresh token present")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRefreshAccess() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("Refresh");
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])
       
        var mockedSession = MockOAuth2SessionWithRefreshToken()
        var oauth2Module = OAuth2Module(config: googleConfig, session: mockedSession)
        oauth2Module.refreshAccessToken { (response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue("NEWLY_REFRESHED_ACCESS_TOKEN" == response as String, "If access token not valid but refresh token present and still valid")
            XCTAssertTrue("REFRESH_TOKEN" == mockedSession.savedRefreshedToken, "Saved newly issued refresh token")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testExchangeAuthorizationCodeForAccessToken() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("AccessRequest");
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])
        
        var oauth2Module = OAuth2Module(config: googleConfig, session: MockOAuth2SessionWithRefreshToken())
        oauth2Module.exchangeAuthorizationCodeForAccessToken ("CODE", completionHandler: {(response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue("NEWLY_REFRESHED_ACCESS_TOKEN" == response as String, "If access token not valid but refresh token present and still valid")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRevokeAccess() {
        setupStubWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("Revoke");
        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])
        
        var mockedSession = MockOAuth2SessionWithRefreshToken()
        var oauth2Module = OAuth2Module(config: googleConfig, session: mockedSession)
        oauth2Module.revokeAccess({(response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue(mockedSession.initCalled == 1, "revoke token reset session")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}