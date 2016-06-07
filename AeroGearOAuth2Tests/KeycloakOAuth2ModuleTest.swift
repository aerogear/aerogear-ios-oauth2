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

let KEYCLOAK_TOKEN = "eyJhbGciOiJSUzI1NiJ9.eyJuYW1lIjoiU2FtcGxlIFVzZXIiLCJlbWFpbCI6InNhbXBsZS11c2VyQGV4YW1wbGUiLCJqdGkiOiI5MTEwNjAwZS1mYTdiLTRmOWItOWEwOC0xZGJlMGY1YTY5YzEiLCJleHAiOjE0MTc2ODg1OTgsIm5iZiI6MCwiaWF0IjoxNDE3Njg4Mjk4LCJpc3MiOiJzaG9vdC1yZWFsbSIsImF1ZCI6InNob290LXJlYWxtIiwic3ViIjoiNzJhN2Q0NGYtZDcxNy00MDk3LWExMWYtN2FhOWIyMmM5ZmU3IiwiYXpwIjoic2hhcmVkc2hvb3QtdGhpcmQtcGFydHkiLCJnaXZlbl9uYW1lIjoiU2FtcGxlIiwiZmFtaWx5X25hbWUiOiJVc2VyIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlciIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwic2Vzc2lvbl9zdGF0ZSI6Ijg4MTJlN2U2LWQ1ZGYtNDc4Yi1iNDcyLTNlYWU5YTI2ZDdhYSIsImFsbG93ZWQtb3JpZ2lucyI6W10sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJ1c2VyIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnt9fQ.ZcNu8C4yeo1ALqnLvEOK3NxnaKm2BR818B4FfqN3WQd3sc6jvtGmTPB1C0MxF6ku_ELVs2l_HJMjNdPT9daUoau5LkdCjSiTwS5KA-18M5AUjzZnVo044-jHr_JsjNrYEfKmJXX0A_Zdly7el2tC1uPjGoeBqLgW9GowRl3i4wE"

func setupStubKeycloakWithNSURLSessionDefaultConfiguration() {
    // set up http stub
    stub({_ in return true}, response: { (request: NSURLRequest!) -> OHHTTPStubsResponse in
            //_ = ["name": "John", "family_name": "Smith"]
            switch request.URL!.path! {

            case "/auth/realms/shoot-realm/tokens/refresh":
                let string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"\(KEYCLOAK_TOKEN)\",\"expires_in\":23}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            case "/auth/realms/shoot-realm/tokens/logout":
                let string = "{\"access_token\":\"NEWLY_REFRESHED_ACCESS_TOKEN\", \"refresh_token\":\"nnn\",\"expires_in\":23}"
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data:data!, statusCode: 200, headers: ["Content-Type" : "text/json"])
            default: return OHHTTPStubsResponse(data:NSData(), statusCode: 404, headers: ["Content-Type" : "text/json"])
            }
        })
}

class KeycloakOAuth2ModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        OHHTTPStubs.removeAllStubs()
        setupStubKeycloakWithNSURLSessionDefaultConfiguration()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }
 /* TODO AGIOS-476
    func testRefreshAccessWithKeycloak() {
        let expectation = expectationWithDescription("KeycloakRefresh");
        let keycloakConfig = KeycloakConfig(
            clientId: "shoot-third-party",
            host: "http://localhost:8080",
            realm: "shoot-realm")

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = KeycloakOAuth2Module(config: keycloakConfig, session: mockedSession)
        oauth2Module.refreshAccessToken ({ (response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue("NEWLY_REFRESHED_ACCESS_TOKEN" == response as! String, "If access token not valid but refresh token present and still valid")
            XCTAssertTrue(KEYCLOAK_TOKEN == mockedSession.savedRefreshedToken, "Saved newly issued refresh token")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRevokeAccess() {
        setupStubKeycloakWithNSURLSessionDefaultConfiguration()
        let expectation = expectationWithDescription("KeycloakRevoke");
        let keycloakConfig = KeycloakConfig(
            clientId: "shoot-third-party",
            host: "http://localhost:8080",
            realm: "shoot-realm")

        let mockedSession = MockOAuth2SessionWithRefreshToken()
        let oauth2Module = KeycloakOAuth2Module(config: keycloakConfig, session: mockedSession)
        oauth2Module.revokeAccess({(response: AnyObject?, error:NSError?) -> Void in
            XCTAssertTrue(mockedSession.initCalled == 1, "revoke token reset session")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
      */
}
