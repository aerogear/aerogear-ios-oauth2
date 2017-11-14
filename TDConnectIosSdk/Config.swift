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

/**
Configuration object to setup an OAuth2 module
*/
open class Config {
    /**
    Applies the baseURL to the configuration.
    */
    open let baseURL: String

    /**
    Applies the "callback URL" once request token issued.
    */
    open let redirectURL: String

    /**
    Applies the "authorization endpoint" to the request token.
    */
    open var authzEndpoint: String

    /**
    Applies the "access token endpoint" to the exchange code for access token.
    */
    open var accessTokenEndpoint: String

    /**
    Endpoint for request to invalidate both accessToken and refreshToken.
    */
    open let revokeTokenEndpoint: String?

    /**
     Endpoint for well known configuration.
     */
    open let wellKnownConfigurationEndpoint: String?

    /**
    Endpoint for request a refreshToken.
    */
    open let refreshTokenEndpoint: String?

    /**
    Endpoint for OpenID Connect to get user information.
    */
    open let userInfoEndpoint: String?
    
    /**
    Endpoint for performing a token-based logout, which will log the user out of any SSO session.
    */
    open let logOutEndpoint: String?

    /**
    Boolean to indicate whether OpenID Connect on authorization code grant flow is used.
    */
    open var isOpenIDConnect: Bool

    /**
    Applies the various scopes of the authorization.
    */
    open var scopes: [String]

    /**
    Returns a string that conatins scopes, separated with spaces and url encoded.
    ["scope1", "scope2"] -> "scope1%20scope2"
    */
    open var scopesEncoded: String {
        get {
            return scopes
                .joined(separator: " ")
                .urlEncode()
        }
    }

    /**
    Applies the "client id" obtained with the client registration process.
    */
    open let clientId: String

    /**
    Applies the "client secret" obtained with the client registration process.
    */
    open let clientSecret: String?

    /**
    Applies the "audience" obtained with the client registration process.
    */
    public let audienceId: String?

    /**
    Account id is used with AccountManager to store tokens. AccountId is defined by the end-user
    and can be any String. If AccountManager is not used, this field is optional.
    */
    open var accountId: String?

    /**
    Optional set of claims that will be formatted as urlencoded json and set as essential.
    Example set: {"openid", "profile", "email", "address", "phone"}
    Intermediate json would be:
     {
     "userinfo":{
       "openid":{"essential":true},
       "profile":{"essential":true},
       "email":{"essential":true},
       "address":{"essential":true},
       "phone":{"essential":true}
       }
     }
    End result will be %7B%22userinfo%22%3A%7B%22openid%22%3A%7B%22essential%22%3Atrue%7D%2C%22profile%22%3A%7B%22essential%22%3Atrue%7D%2C%22email%22%3A%7B%22essential%22%3Atrue%7D%2C%22address%22%3A%7B%22essential%22%3Atrue%7D%2C%22phone%22%3A%7B%22essential%22%3Atrue%7D%7D%7D
    */
    public var claims: Set<String>?
    
    /**
    This dict can be used to set optional query params such as state, prompt, max_age, ui_locales, login_hint and acr_values.
    */
    public var optionalParams: [String: String]?
    
    /**
    Boolean to indicate to either used a webview (if true) or an external browser (by default, false)
    for authorization code grant flow.
    */
    open var isWebView: Bool = false
    
    /**
    Boolean to indicate whether the client is a public client (true) or a confidential client (false).
    A public client will exchange the authorization code for tokens, on successful authentication and authorization.
    A confidential client will not exchange the authorization code but simply return this to the client through the callback, on successful authentication and authorization.
    */
    public let isPublicClient: Bool
    
    /**
    A handler to allow the webview to be pushed onto the navigation controller
    */
    open var webViewHandler: ((OAuth2WebViewController, _ completionHandler: (AnyObject?, NSError?) -> Void) -> ()) = {
        (webView, completionHandler) in
        UIApplication.shared.keyWindow?.rootViewController?.present(webView, animated: true, completion: nil)
    }

    public init(base: String, authzEndpoint: String, redirectURL: String, accessTokenEndpoint: String, clientId: String, audienceId: String? = nil, refreshTokenEndpoint: String? = nil, revokeTokenEndpoint: String? = nil, wellKnownConfigurationEndpoint: String? = nil, isOpenIDConnect: Bool = false, userInfoEndpoint: String? = nil, logOutEndpoint: String? = nil, scopes: [String] = [],  clientSecret: String? = nil, accountId: String? = nil, claims: Set<String>? = nil, optionalParams: [String: String]? = nil, isWebView: Bool = false, isPublicClient: Bool = true) {
        self.baseURL = base
        self.authzEndpoint = authzEndpoint
        self.redirectURL = redirectURL
        self.accessTokenEndpoint = accessTokenEndpoint
        self.refreshTokenEndpoint = refreshTokenEndpoint
        self.revokeTokenEndpoint = revokeTokenEndpoint
        self.wellKnownConfigurationEndpoint = wellKnownConfigurationEndpoint
        self.isOpenIDConnect = isOpenIDConnect
        self.userInfoEndpoint = userInfoEndpoint
        self.logOutEndpoint = logOutEndpoint
        self.scopes = scopes
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.audienceId = audienceId
        self.accountId = accountId
        self.claims = claims
        self.optionalParams = optionalParams
        self.isWebView = isWebView
        self.isPublicClient = isPublicClient
    }
}
