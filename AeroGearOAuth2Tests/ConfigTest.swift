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

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGoogleConfigWithoutOpenID() {
        let googleConfig = GoogleConfig(
            clientId: "873670803862-g6pjsgt64gvp7r25edgf4154e8sld5nq.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"])

        XCTAssert(googleConfig.scopes.filter({$0 == "openid"}) == [], "no openid defined per default")
        XCTAssert(googleConfig.scopes == ["https://www.googleapis.com/auth/drive"], "no openid defined per default")
    }

    func testGoogleConfigWithOpenID() {
        let googleConfig = GoogleConfig(
            clientId: "873670803862-g6pjsgt64gvp7r25edgf4154e8sld5nq.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"],
            isOpenIDConnect: true)

        XCTAssert(googleConfig.scopes.filter({$0 == "openid"}) == ["openid"], "openid defined for Open ID Connect config")
        XCTAssert(googleConfig.scopes.filter({$0 == "profile"}) == ["profile"], "profile defined for Open ID Connect config")
        XCTAssert(googleConfig.scopes.filter({$0 == "email"}) == ["email"], "email defined for Open ID Connect config")
    }

    func testFacebookConfigWithoutOpenID() {
        let facebookConfig = FacebookConfig(
            clientId: "clientid",
            clientSecret: "secret",
            scopes:["photo_upload, publish_actions"])
        print(facebookConfig.scopes)
        XCTAssert(facebookConfig.scopes[0].rangeOfString("public_profile") == nil, "no public_profile defined per default")
    }

    func testFacebookConfigWithOpenID() {
        let facebookConfig = FacebookConfig(
            clientId: "clientid",
            clientSecret: "secret",
            scopes:["photo_upload, publish_actions"],
            isOpenIDConnect: true)
        print(facebookConfig.scopes)
        XCTAssert(facebookConfig.scopes[0] == "photo_upload, publish_actions, public_profile", "public_profile defined for Open ID Connect config, facebook does not use openid")

    }

    func testKeycloakConfigWithoutOpenID() {
        let keycloakConfig = KeycloakConfig(
            clientId: "shoot-third-party",
            host: "http://localhost:8080",
            realm: "shoot-realm")

        XCTAssert(keycloakConfig.scopes.filter({$0 == "openid"}) == [], "no openid defined per default")
    }

    func testkeycloakConfigWithOpenID() {
        let keycloakConfig = KeycloakConfig(
            clientId: "shoot-third-party",
            host: "http://localhost:8080",
            realm: "shoot-realm",
            isOpenIDConnect: true)

        XCTAssert(keycloakConfig.scopes.filter({$0 == "openid"}) == ["openid"], "openid defined for Open ID Connect config")
        XCTAssert(keycloakConfig.scopes.filter({$0 == "profile"}) == ["profile"], "profile defined for Open ID Connect config")
        XCTAssert(keycloakConfig.scopes.filter({$0 == "email"}) == ["email"], "email defined for Open ID Connect config")
    }

}
