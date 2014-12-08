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
            default: return StubResponse(data:NSData(), statusCode: 200, headers: ["Content-Type" : "text/json"])
            }
        }))
}

class FacebookOAuth2ModuleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        StubsManager.removeAllStubs()
    }
    
    class MyFacebookMockOAuth2ModuleSuccess: FacebookOAuth2Module {
        
        override func requestAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
            var accessToken: AnyObject? = NSString(string:"TOKEN")
            completionHandler(accessToken, nil)
        }
    }
    
    class MyFacebookMockOAuth2ModuleFailure: FacebookOAuth2Module {
        
        override func requestAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
            completionHandler(nil, NSError())
        }
    }
    
    func testFacebookOpenIDSuccess() {
        let loginExpectation = expectationWithDescription("Login");
        
        let facebookConfig = FacebookConfig(
            clientId: "YYY",
            clientSecret: "XXX",
            scopes:["photo_upload, publish_actions"],
            isOpenIDConnect: true)
        
        // set up http stub
        setupStubWithNSURLSessionDefaultConfiguration()
        var oauth2Module = AccountManager.addAccount(facebookConfig, moduleClass: MyFacebookMockOAuth2ModuleSuccess.self)
        
        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIDClaim?, error: NSError?) in
            
            XCTAssertTrue("Corinne Krych" == claims?.name, "name should be filled")
            XCTAssertTrue("Corinne" == claims?.givenName, "first name should be filled")
            XCTAssertTrue("Krych" == claims?.familyName, "family name should be filled")
            XCTAssertTrue("female" == claims?.gender, "gender should be filled")
            loginExpectation.fulfill()
            
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testFacebookOpenIDFailureNoUserInfoEndPoint() {
        let loginExpectation = expectationWithDescription("Login");
        
        let fbConfig = Config(base: "https://fb",
            authzEndpoint: "o/oauth2/auth",
            redirectURL: "google:/oauth2Callback",
            accessTokenEndpoint: "o/oauth2/token",
            clientId: "302356789040-eums187utfllgetv6kmbems0pm3mfhgl.apps.googleusercontent.com",
            refreshTokenEndpoint: "o/oauth2/token",
            revokeTokenEndpoint: "rest/revoke",
            isOpenIDConnect: true,
            userInfoEndpoint: nil,
            scopes: ["openid", "email", "profile"],
            accountId: "acc")
        // set up http stub
        setupStubWithNSURLSessionDefaultConfiguration()
        var oauth2Module = AccountManager.addAccount(fbConfig, moduleClass: MyFacebookMockOAuth2ModuleSuccess.self)
        
        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIDClaim?, error: NSError?) in
            var erroDict = (error?.userInfo)!
            var value = erroDict["OpenID Connect"] as String
            XCTAssertTrue( value == "No UserInfo endpoint available in config", "claim shoud be as mocked")
            loginExpectation.fulfill()
            
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testFacebookOpenIDFailure() {
        let loginExpectation = expectationWithDescription("Login");
        
        let facebookConfig = FacebookConfig(
            clientId: "YYY",
            clientSecret: "XXX",
            scopes:["photo_upload, publish_actions"],
            isOpenIDConnect: true)
        
        
        var oauth2Module = AccountManager.addAccount(facebookConfig, moduleClass: MyFacebookMockOAuth2ModuleFailure.self)
        
        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIDClaim?, error: NSError?) in
            
            XCTAssertTrue(error != nil, "Error")
            loginExpectation.fulfill()
            
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}