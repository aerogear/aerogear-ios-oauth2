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
public class Config {
    /**
    Applies the baseURL to the configuration.
    */
    public let baseURL: String

    /**
    Applies the "callback URL" once request token issued.
    */
    public let redirectURL: String

    /**
    Applies the "authorization endpoint" to the request token.
    */
    public var authzEndpoint: String

    /**
    Applies the "access token endpoint" to the exchange code for access token.
    */
    public var accessTokenEndpoint: String

    /**
    Endpoint for request to invalidate both accessToken and refreshToken.
    */
    public let revokeTokenEndpoint: String?

    /**
    Endpoint for request a refreshToken.
    */
    public let refreshTokenEndpoint: String?

    /**
    Endpoint for OpenID Connect to get user information.
    */
    public let userInfoEndpoint: String?

    /**
    Boolean to indicate whether OpenID Connect on authorization code grant flow is used.
    */
    public var isOpenIDConnect: Bool

    /**
    Applies the various scopes of the authorization.
    */
    public var scopes: [String]

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
    public let clientId: String

    /**
    Applies the "client secret" obtained with the client registration process.
    */
    public let clientSecret: String?

    /**
    Account id is used with AccountManager to store tokens. AccountId is defined by the end-user
    and can be any String. If AccountManager is not used, this field is optional.
    */
    public var accountId: String?

    /**
    Boolean to indicate to either used a webview (if true) or an external browser (by default, false)
    for authorization code grant flow.
    */
    public var isWebView: Bool = false

    /**
    A handler to allow the webview to be pushed onto the navigation controller
    */
    public var webViewHandler: ((OAuth2WebViewController, completionHandler: (AnyObject?, NSError?) -> Void) -> ()) = {
        (webView, completionHandler) in
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(webView, animated: true, completion: nil)
    }

    public init(base: String, authzEndpoint: String, redirectURL: String, accessTokenEndpoint: String, clientId: String, refreshTokenEndpoint: String? = nil, revokeTokenEndpoint: String? = nil, isOpenIDConnect: Bool = false, userInfoEndpoint: String? = nil, scopes: [String] = [],  clientSecret: String? = nil, accountId: String? = nil, isWebView: Bool = false) {
        self.baseURL = base
        self.authzEndpoint = authzEndpoint
        self.redirectURL = redirectURL
        self.accessTokenEndpoint = accessTokenEndpoint
        self.refreshTokenEndpoint = refreshTokenEndpoint
        self.revokeTokenEndpoint = revokeTokenEndpoint
        self.isOpenIDConnect = isOpenIDConnect ?? false
        self.userInfoEndpoint = userInfoEndpoint
        self.scopes = scopes
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.accountId = accountId
        self.isWebView = isWebView
    }
}
