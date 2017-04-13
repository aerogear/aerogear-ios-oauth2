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

open class MockOAuth2SessionWithValidAccessTokenStored: OAuth2Session {
    open var accountId: String {
        get {
            return "account"
        }
    }
    open var accessToken: String? {
        get {
            return "TOKEN"
        }
        set(data) {}
    }
    open var accessTokenExpirationDate: Date?
    open var refreshTokenExpirationDate: Date?
    open var refreshToken: String?
    open var idToken: String?
    open var serverCode: String?
    open func tokenIsNotExpired() -> Bool {
        return true
    }

    open func refreshTokenIsNotExpired() -> Bool {
        return true
    }

    open func clearTokens() {}
    open func save(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?, idToken: String?) {}
    public init() {}
}

open class MockOAuth2SessionWithRefreshToken: MockOAuth2SessionWithValidAccessTokenStored {
    open var savedRefreshedToken: String?
    open var initCalled = 0
    open override var refreshToken: String? {
        get {
            return "REFRESH_TOKEN"
        }
        set(data) {}
    }
    override open var accessTokenExpirationDate: Date? {
        get {
            return Date()
        }
        set(value) {}
    }
    override open var refreshTokenExpirationDate: Date? {
        get {
            return Date()
        }
        set(value) {}
    }

    open override func tokenIsNotExpired() -> Bool {
        return false
    }
    open override func save(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?, idToken: String?) {
        savedRefreshedToken = refreshToken
    }
    open override func clearTokens() {initCalled = 1}
    public override init() {}
}

open class MockOAuth2SessionWithAuthzCode: MockOAuth2SessionWithValidAccessTokenStored {
    open override var refreshToken: String? {
        get {
            return nil
        }
        set(data) {}
    }
    open override func tokenIsNotExpired() -> Bool {
        return false
    }

}

class OAuth2ModulePartialMock: OAuth2Module {
    override func refreshAccessToken(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        completionHandler("NEW_ACCESS_TOKEN" as AnyObject?, nil)
    }
    override func requestAuthorizationCode(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        completionHandler("ACCESS_TOKEN" as AnyObject?, nil)
    }
}
