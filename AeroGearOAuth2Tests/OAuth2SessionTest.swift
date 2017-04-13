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

class OAuth2SessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitUntrustedMemoryOAuth2SessionWithoutAccessToken() {
        let session = UntrustedMemoryOAuth2Session(accountId: "MY_FACEBOOK_ID")
        XCTAssert(session.accountId == "MY_FACEBOOK_ID", "wrong account id")
        XCTAssert(session.accessToken ==  nil, "session should be without access token")
    }

    func testInitUntrustedMemoryOAuth2SessionWithAccessToken() {
        let session = UntrustedMemoryOAuth2Session(accountId: "MY_FACEBOOK_ID", accessToken: "ACCESS", accessTokenExpirationDate: Date())
        XCTAssert(session.accountId == "MY_FACEBOOK_ID", "wrong account id")
        XCTAssert(session.accessToken ==  "ACCESS", "session should be with access token")
        XCTAssert(session.accessTokenExpirationDate !=  nil, "session should be with access token expiration date")
    }

    func testSaveNilTokens() {
        let session = UntrustedMemoryOAuth2Session(accountId: "MY_FACEBOOK_ID", accessToken: "ACCESS", refreshToken: "REFRESH")
        session.clearTokens()
        XCTAssert(session.accountId == "MY_FACEBOOK_ID", "wrong account id")
        XCTAssert(session.accessToken ==  nil, "session should be without access token")
        XCTAssert(session.refreshToken ==  nil, "session should be without refresh token")
        XCTAssert(session.accessTokenExpirationDate ==  nil, "session should be without access token expiration date")
    }

    func testSaveTokens() {
        let session = UntrustedMemoryOAuth2Session(accountId: "MY_FACEBOOK_ID", accessToken: "ACCESS", accessTokenExpirationDate: Date(), refreshToken: "REFRESH")
        session.clearTokens()
        XCTAssert(session.accountId == "MY_FACEBOOK_ID", "wrong account id")
        XCTAssert(session.accessToken ==  nil, "session should be without access token")
        XCTAssert(session.refreshToken ==  nil, "session should be without refresh token")
        XCTAssert(session.accessTokenExpirationDate ==  nil, "session should be without access token expiration date")
    }

}
