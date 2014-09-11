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

public class Config {
    /**
    * Applies the baseURL to the configuration.
    */
    public let base: String
    
    public var baseURL:NSURL {
        get {
            return NSURL.URLWithString(base)
        }
    }
    
    /**
    * Applies the "authorization endpoint" to the request token.
    */
    public let authzEndpoint: String
    
    public var authzEndpointURL: NSURL {
        get {
            if authzEndpoint.hasPrefix("http") {
                return NSURL(string: authzEndpoint)
            } else {
                var formattedEndpoint = authzEndpoint.hasPrefix("/") ? (authzEndpoint as NSString).substringFromIndex(1) : authzEndpoint
                return baseURL.URLByAppendingPathComponent(formattedEndpoint)
            }
        }
    }
    
    /**
    * Applies the "callback URL" once request token issued.
    */
    public let redirectURL: String
    
    /**
    * Applies the "access token endpoint" to the exchange code for access token.
    */
    public let accessTokenEndpoint: String
    
    /**
    * Computed property to get URL by taking care of extra or missing pre or postfix '/'.
    */
    public var accessTokenEndpointURL: NSURL {
        get {
            if accessTokenEndpoint.hasPrefix("http") {
                return NSURL(string: accessTokenEndpoint)
            } else {
                var formattedEndpoint = accessTokenEndpoint.hasPrefix("/") ? (accessTokenEndpoint as NSString).substringFromIndex(1) : accessTokenEndpoint
                return baseURL.URLByAppendingPathComponent(formattedEndpoint)
            }
        }
    }
    
    /**
    * Endpoint for request to invalidate both accessToken and refreshToken.
    */
    public let revokeTokenEndpoint: String?
    
    /**
    * Computed property to get URL by taking care of extra or missing pre or postfix '/'.
    */
    public var revokeTokenEndpointURL: NSURL? {
        get {
            if let unwrappedRevokeTokenEndpoint = revokeTokenEndpoint {
                if (revokeTokenEndpoint != nil && revokeTokenEndpoint!.hasPrefix("http")) {
                    return NSURL(string: revokeTokenEndpoint!)
                } else {
                    var formattedEndpoint = unwrappedRevokeTokenEndpoint.hasPrefix("/") ? (unwrappedRevokeTokenEndpoint as NSString).substringFromIndex(1) : unwrappedRevokeTokenEndpoint
                    return baseURL.URLByAppendingPathComponent(formattedEndpoint)
                }
            } else {
                return nil
            }
        }
    }
    
    /**
    * Applies the various scopes of the authorization.
    */
    public let scopes: [String]
    
    /**
    * Applies the "client id" obtained with the client registration process.
    */
    public let clientId: String
    
    /**
    * Applies the "client secret" obtained with the client registration process.
    */
    public let clientSecret: String?
    
    /**
    * Account id is used with AccountManager to store tokens. AccountId is defined by the end-user 
    * and can be any String. If AccountManager is not used, this field is optional.
    */
    public let accountId: String?
    
    public init(base: String, authzEndpoint: String, redirectURL: String, accessTokenEndpoint: String, clientId: String, revokeTokenEndpoint: String? = nil, scopes: [String] = [],  clientSecret: String? = nil, accountId: String? = nil) {
        self.base = base
        self.authzEndpoint = authzEndpoint
        self.redirectURL = redirectURL
        self.accessTokenEndpoint = accessTokenEndpoint
        self.revokeTokenEndpoint = revokeTokenEndpoint
        self.scopes = scopes
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.accountId = accountId
    }
}