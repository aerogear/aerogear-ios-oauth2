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

public class OAuth2Session {
    
    /**
    * The account id.
    */
    public let accountId: String
    
    /**
    * The access token which expires.
    */
    var accessToken: String?
    
    /**
    * The access token's expiration date.
    */
    var accessTokenExpirationDate: NSDate?
    
    /**
    * The refresh tokens. This toke does not expire and should be used to renew access token when expired.
    */
    var refreshToken: String?
    
    /**
    * Check validity of accessToken. return true if still valid, false when expired.
    */
    func tokenIsNotExpired() -> Bool {
        return self.accessTokenExpirationDate?.timeIntervalSinceDate(NSDate()) > 0 ;
    }
    
    /**
    * Save in memory tokens information. Saving tokens allow you to refresh accesstoken transparently for the user without prompting
    * for grant access.
    */
    func saveAccessToken(accessToken: String? = nil, refreshToken: String? = nil, expiration: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        let now = NSDate()
        if let inter = expiration?.doubleValue {
            self.accessTokenExpirationDate = now.dateByAddingTimeInterval(inter)
        }
    }
    
    public init(accountId: String, accessToken: String? = nil, accessTokenExpirationDate: NSDate? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.accessTokenExpirationDate = accessTokenExpirationDate
        self.refreshToken = refreshToken
        self.accountId = accountId
    }
}
