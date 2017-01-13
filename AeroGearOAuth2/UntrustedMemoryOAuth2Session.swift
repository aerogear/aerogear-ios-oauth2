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

extension String {
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
}

/**
An OAuth2Session implementation the stores OAuth2 metadata in-memory
*/
open class UntrustedMemoryOAuth2Session: OAuth2Session {

    /**
    The account id.
    */
    open var accountId: String

    /**
    The access token which expires.
    */
    open var accessToken: String?

    /**
    The access token's expiration date.
    */
    open var accessTokenExpirationDate: Date?

    /**
    The refresh tokens. This toke does not expire and should be used to renew access token when expired.
    */
    open var refreshToken: String?

    /**
    The refresh token's expiration date.
    */
    open var refreshTokenExpirationDate: Date?

    /**
    The JWT which expires.
    */
    open var idToken: String?

    /**
    Check validity of accessToken. return true if still valid, false when expired.
    */
    open func tokenIsNotExpired() -> Bool {
        return self.accessTokenExpirationDate != nil ? (self.accessTokenExpirationDate!.timeIntervalSince(Date()) > 0) : true
    }

    /**
    Check validity of refreshToken. return true if still valid, false when expired.
    */
    open func refreshTokenIsNotExpired() -> Bool {
        return self.refreshTokenExpirationDate != nil ? (self.refreshTokenExpirationDate!.timeIntervalSince(Date()) > 0) : true
    }

    /**
    Save in memory tokens information. Saving tokens allow you to refresh accessToken transparently for the user without prompting for grant access.
    */
    open func save(accessToken: String?, refreshToken: String?, accessTokenExpiration: String?, refreshTokenExpiration: String?, idToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        let now = Date()
        if let inter = accessTokenExpiration?.doubleValue {
            self.accessTokenExpirationDate = now.addingTimeInterval(inter)
        }
        if let interRefresh = refreshTokenExpiration?.doubleValue {
            self.refreshTokenExpirationDate = now.addingTimeInterval(interRefresh)
        }
    }

    /**
    Clear all tokens. Method used when doing logout or revoke.
    */
    open func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        self.accessTokenExpirationDate = nil
        self.refreshTokenExpirationDate = nil
    }

    /**
    Initialize session using account id.

    :param: accountId uniqueId to identify the OAuth2Module.
    :param: accessToken optional parameter to initialize the storage with initial values.
    :param: accessTokenExpirationDate optional parameter to initialize the storage with initial values.
    :param: refreshToken optional parameter to initialize the storage with initial values.
    :param: refreshTokenExpirationDate optional parameter to initialize the storage with initial values.
    */
    public init(accountId: String, accessToken: String? = nil, accessTokenExpirationDate: Date? = nil, refreshToken: String? = nil, refreshTokenExpirationDate: Date? = nil) {
        self.accessToken = accessToken
        self.accessTokenExpirationDate = accessTokenExpirationDate
        self.refreshToken = refreshToken
        self.refreshTokenExpirationDate = refreshTokenExpirationDate
        self.accountId = accountId
    }
}
