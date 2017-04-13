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

class OpenIDConnectFacebookOAuth2ModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    class MyFacebookMockOAuth2ModuleSuccess: FacebookOAuth2Module {

        override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            let accessToken: AnyObject? = NSString(string:"TOKEN")
            completionHandler(accessToken, nil)
        }
    }

    class MyFacebookMockOAuth2ModuleFailure: FacebookOAuth2Module {

        override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            completionHandler(nil, NSError(domain: "", code: 0, userInfo: nil))
        }
    }

    func testFacebookOpenIDSuccess() {
        let loginExpectation = expectation(description: "Login")

        let facebookConfig = FacebookConfig(
            clientId: "YYY",
            clientSecret: "XXX",
            scopes:["publish_actions"],
            isOpenIDConnect: true)

        // set up http stub
        setupStubWithNSURLSessionDefaultConfiguration()
        let oauth2Module = AccountManager.addAccountWith(config: facebookConfig, moduleClass: MyFacebookMockOAuth2ModuleSuccess.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in

            XCTAssertTrue("Corinne Krych" == claims?.name, "name should be filled")
            XCTAssertTrue("Corinne" == claims?.givenName, "first name should be filled")
            XCTAssertTrue("Krych" == claims?.familyName, "family name should be filled")
            XCTAssertTrue("female" == claims?.gender, "gender should be filled")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFacebookOpenIDFailureNoUserInfoEndPoint() {
        let loginExpectation = expectation(description: "Login")

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
        let oauth2Module = AccountManager.addAccountWith(config: fbConfig, moduleClass: MyFacebookMockOAuth2ModuleSuccess.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in
            var erroDict = (error?.userInfo)!
            let value = erroDict["OpenID Connect"] as! String
            XCTAssertTrue( value == "No UserInfo endpoint available in config", "claim should be as mocked")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFacebookOpenIDFailure() {
        let loginExpectation = expectation(description: "Login")

        let facebookConfig = FacebookConfig(
            clientId: "YYY",
            clientSecret: "XXX",
            scopes:["photo_upload, publish_actions"],
            isOpenIDConnect: true)


        let oauth2Module = AccountManager.addAccountWith(config: facebookConfig, moduleClass: MyFacebookMockOAuth2ModuleFailure.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in

            XCTAssertTrue(error != nil, "Error")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
