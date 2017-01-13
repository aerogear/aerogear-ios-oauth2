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
An OAuth2Module subclass specific to 'Keycloak' authorization
*/
open class KeycloakOAuth2Module: OAuth2Module {

    open override func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return
        }
        // return if no revoke endpoint
        guard let revokeTokenEndpoint = config.revokeTokenEndpoint else {
            return
        }

        let paramDict: [String:String] = [ "client_id": config.clientId, "refresh_token": self.oauth2Session.refreshToken!]
        http.request(method: .post, path: revokeTokenEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }

            self.oauth2Session.clearTokens()
            completionHandler(response as AnyObject?, nil)
        })
    }

    /**
    Gateway to login with OpenIDConnect

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open override func login(completionHandler: @escaping (AnyObject?, OpenIdClaim?, NSError?) -> Void) {
        var openIDClaims: OpenIdClaim?

        self.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            if (error != nil) {
                completionHandler(nil, nil, error)
                return
            }
            let accessToken = response as? String
            if let accessToken = accessToken {
                let token = self.decode(accessToken)
                if let decodedToken = token {
                    openIDClaims = OpenIdClaim(fromDict: decodedToken)
                }
            }
            completionHandler(accessToken as AnyObject?, openIDClaims, nil)
        }
    }

    /**
    Request to refresh an access token.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    open override func refreshAccessToken(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        if let unwrappedRefreshToken = self.oauth2Session.refreshToken {
            var paramDict: [String: String] = ["refresh_token": unwrappedRefreshToken, "client_id": config.clientId, "grant_type": "refresh_token"]
            if (config.clientSecret != nil) {
                paramDict["client_secret"] = config.clientSecret!
            }

            http.request(method: .post, path: config.refreshTokenEndpoint!, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in
                if (error != nil) {
                    completionHandler(nil, error)
                    return
                }

                if let unwrappedResponse = response as? [String: AnyObject] {
                    let accessToken: String = unwrappedResponse["access_token"] as! String
                    let refreshToken: String = unwrappedResponse["refresh_token"] as! String
                    let expiration = unwrappedResponse["expires_in"] as! NSNumber
                    let exp: String = expiration.stringValue
                    let expirationRefresh = unwrappedResponse["refresh_expires_in"] as? NSNumber
                    let expRefresh = expirationRefresh?.stringValue

                    // in Keycloak refresh token get refreshed every time you use them
                    self.oauth2Session.save(accessToken: accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: expRefresh, idToken: nil)
                    completionHandler(accessToken as AnyObject?, nil)
                }
            })
        }
    }


    func decode(_ token: String) -> [String: AnyObject]? {
        let string = token.components(separatedBy: ".")
        let toDecode = string[1] as String


        var stringtoDecode: String = toDecode.replacingOccurrences(of: "-", with: "+") // 62nd char of encoding
        stringtoDecode = stringtoDecode.replacingOccurrences(of: "_", with: "/") // 63rd char of encoding
        switch (stringtoDecode.utf16.count % 4) {
        case 2: stringtoDecode = "\(stringtoDecode)=="
        case 3: stringtoDecode = "\(stringtoDecode)="
        default: // nothing to do stringtoDecode can stay the same
            print("")
        }
        let dataToDecode = Data(base64Encoded: stringtoDecode, options: [])
        let base64DecodedString = NSString(data: dataToDecode!, encoding: String.Encoding.utf8.rawValue)

        var values: [String: AnyObject]?
        if let string = base64DecodedString {
            if let data = string.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true) {
                values = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject]
            }
        }
        return values
    }

}
