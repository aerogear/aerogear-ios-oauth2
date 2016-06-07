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

import Foundation
import AeroGearOAuth2

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

    public func clearTokens() {}

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
    override public var accessTokenExpirationDate: NSDate? {
        get {
            return NSDate()
        }
        set(value) {}
    }
    override public var refreshTokenExpirationDate: NSDate? {
        get {
            return NSDate()
        }
        set(value) {}
    }

    public override func tokenIsNotExpired() -> Bool {
        return false
    }
    public override func saveAccessToken(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?) {
        savedRefreshedToken = refreshToken
    }
    public override func clearTokens() {initCalled = 1}
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
