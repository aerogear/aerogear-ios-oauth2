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

class OpenIDConnectKeycloakOAuth2ModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    class MyKeycloakMockOAuth2ModuleSuccess: KeycloakOAuth2Module {

        override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            let accessToken: AnyObject? = NSString(string: "eyJhbGciOiJSUzI1NiJ9.eyJuYW1lIjoiU2FtcGxlIFVzZXIiLCJlbWFpbCI6InNhbXBsZS11c2VyQGV4YW1wbGUiLCJqdGkiOiI5MTEwNjAwZS1mYTdiLTRmOWItOWEwOC0xZGJlMGY1YTY5YzEiLCJleHAiOjE0MTc2ODg1OTgsIm5iZiI6MCwiaWF0IjoxNDE3Njg4Mjk4LCJpc3MiOiJzaG9vdC1yZWFsbSIsImF1ZCI6InNob290LXJlYWxtIiwic3ViIjoiNzJhN2Q0NGYtZDcxNy00MDk3LWExMWYtN2FhOWIyMmM5ZmU3IiwiYXpwIjoic2hhcmVkc2hvb3QtdGhpcmQtcGFydHkiLCJnaXZlbl9uYW1lIjoiU2FtcGxlIiwiZmFtaWx5X25hbWUiOiJVc2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlciIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwic2Vzc2lvbl9zdGF0ZSI6Ijg4MTJlN2U2LWQ1ZGYtNDc4Yi1iNDcyLTNlYWU5YTI2ZDdhYSIsImFsbG93ZWQtb3JpZ2lucyI6W10sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJ1c2VyIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnt9fQ.ZcNu8C4yeo1ALqnLvEOK3NxnaKm2BR818B4FfqN3WQd3sc6jvtGmTPB1C0MxF6ku_ELVs2l_HJMjNdPT9daUoau5LkdCjSiTwS5KA-18M5AUjzZnVo044-jHr_JsjNrYEfKmJXX0A_Zdly7el2tC1uPjGoeBqLgW9GowRl3i4wE")
            completionHandler(accessToken, nil)
        }
    }

    class MyKeycloakMockOAuth2ModuleFailure: KeycloakOAuth2Module {

        override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            completionHandler(nil, NSError(domain: "", code: 0, userInfo: nil))
        }
    }

    func testKeycloakOpenIDSuccess() {
        let loginExpectation = expectation(description: "Login")

        let keycloakConfig = KeycloakConfig(
            clientId: "shoot-third-party",
            host: "http://localhost:8080",
            realm: "shoot-realm",
            isOpenIDConnect: true)

        let oauth2Module = AccountManager.addAccountWith(config: keycloakConfig, moduleClass: MyKeycloakMockOAuth2ModuleSuccess.self)
        // no need of http stub as Keycloak does not provide a UserInfo endpoint but decode JWT token
        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in
            XCTAssertTrue("Sample User" == claims?.name, "name claim should be as defined in JWT token")
            XCTAssertTrue("User" == claims?.familyName, "family name claim should be as defined in JWT token")
            XCTAssertTrue("sample-user@example" == claims?.email, "email claim should be as defined in JWT token")
            XCTAssertTrue("Sample" == claims?.givenName, "given name claim should be as defined in JWT token")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testKeycloakOpenIDFailure() {
        let loginExpectation = expectation(description: "Login")

        let keycloakConfig = KeycloakConfig(
            clientId: "shoot-third-party",
            host: "http://localhost:8080",
            realm: "shoot-realm",
            isOpenIDConnect: true)


        let oauth2Module = AccountManager.addAccountWith(config: keycloakConfig, moduleClass: MyKeycloakMockOAuth2ModuleFailure.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in

            XCTAssertTrue(error != nil, "Error")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

}
