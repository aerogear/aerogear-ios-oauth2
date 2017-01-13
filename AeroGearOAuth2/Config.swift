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
    Endpoint for request a refreshToken.
    */
    open let refreshTokenEndpoint: String?

    /**
    Endpoint for OpenID Connect to get user information.
    */
    open let userInfoEndpoint: String?

    /**
    Boolean to indicate whether OpenID Connect on authorization code grant flow is used.
    */
    open var isOpenIDConnect: Bool

    /**
    Applies the various scopes of the authorization.
    */
    open var scopes: [String]

    var scope: String {
        get {
            // Create a string to concatenate all scopes existing in the _scopes array.
            var scopeString = ""
            for scope in self.scopes {
                scopeString += scope.urlEncode()
                // If the current scope is other than the last one, then add the "+" sign to the string to separate the scopes.
                if (scope != self.scopes.last) {
                    scopeString += "+"
                }
            }
            return scopeString
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
    Boolean to indicate to either used a webview (if true) or an external browser (by default, false)
    for authorization code grant flow.
    */
    open var isWebView: Bool = false

    /**
    A handler to allow the webview to be pushed onto the navigation controller
    */
    open var webViewHandler: ((OAuth2WebViewController, _ completionHandler: (AnyObject?, NSError?) -> Void) -> ()) = {
        (webView, completionHandler) in
        UIApplication.shared.keyWindow?.rootViewController?.present(webView, animated: true, completion: nil)
    }

    public init(base: String, authzEndpoint: String, redirectURL: String, accessTokenEndpoint: String, clientId: String, audienceId: String? = nil, refreshTokenEndpoint: String? = nil, revokeTokenEndpoint: String? = nil, isOpenIDConnect: Bool = false, userInfoEndpoint: String? = nil, scopes: [String] = [],  clientSecret: String? = nil, accountId: String? = nil, isWebView: Bool = false) {
        self.baseURL = base
        self.authzEndpoint = authzEndpoint
        self.redirectURL = redirectURL
        self.accessTokenEndpoint = accessTokenEndpoint
        self.refreshTokenEndpoint = refreshTokenEndpoint
        self.revokeTokenEndpoint = revokeTokenEndpoint
        self.isOpenIDConnect = isOpenIDConnect
        self.userInfoEndpoint = userInfoEndpoint
        self.scopes = scopes
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.audienceId = audienceId
        self.accountId = accountId
        self.isWebView = isWebView
    }
}
