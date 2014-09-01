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

class ConfigTests: XCTestCase {
    //public init(base: String, authzEndpoint: String, redirectURL: String, accessTokenEndpoint: String, clientId: String, revokeTokenEndpoint: String? = nil, scopes: [String] = [],  clientSecret: String? = nil, accountId: String? = nil) {

    let myConfig1 = Config(base: "http://someserver.com", authzEndpoint: "rest/authz", redirectURL: "redirect", accessTokenEndpoint: "rest/access", clientId: "id", revokeTokenEndpoint: "rest/revoke")
    let myConfig2 = Config(base: "http://someserver.com/", authzEndpoint: "rest/authz", redirectURL: "redirect", accessTokenEndpoint: "rest/access", clientId: "id", revokeTokenEndpoint: "rest/revoke")
    let myConfig3 = Config(base: "http://someserver.com/", authzEndpoint: "/rest/authz", redirectURL: "redirect", accessTokenEndpoint: "rest/access", clientId: "id", revokeTokenEndpoint: "rest/revoke")
    let myConfig4 = Config(base: "http://someserver.com", authzEndpoint: "/rest/authz", redirectURL: "redirect", accessTokenEndpoint: "rest/access", clientId: "id", revokeTokenEndpoint: "rest/revoke")
    var configs: [Config] = []
    
    enum Endpoint {
        case AuthzCode
        case AccessToken
        case RevokeToken
    }
    
    func assertEndpointFormatting(urlString: String, endpoint: Endpoint) {
        map(configs, {(element: Config) -> () in
            switch(endpoint) {
            case .AuthzCode: XCTAssert(element.authzEndpointURL.standardizedURL == NSURL(string: urlString), "correctly formed URL")
            case .AccessToken: XCTAssert(element.accessTokenEndpointURL.standardizedURL == NSURL(string: urlString), "correctly formed URL")
            case .RevokeToken: XCTAssert(element.revokeTokenEndpointURL?.standardizedURL == NSURL(string: urlString), "correctly formed URL")
            default: XCTAssert(false, "no case found")
            }
        })
    }
    
    override func setUp() {
        super.setUp()
        configs = [myConfig1, myConfig2, myConfig3, myConfig4]
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testComputedAccessURL() {
        assertEndpointFormatting("http://someserver.com/rest/access", endpoint: .AccessToken)
    }
    
    func testComputedAuthzEndpointURL() {
        assertEndpointFormatting("http://someserver.com/rest/authz", endpoint: .AuthzCode)
    }
    
    func testComputedRevokeEndpointURL() {
        assertEndpointFormatting("http://someserver.com/rest/revoke", endpoint: .RevokeToken)
    }
}
