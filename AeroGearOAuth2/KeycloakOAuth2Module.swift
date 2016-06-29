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
public class KeycloakOAuth2Module: OAuth2Module {

    public override func revokeAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return
        }
        let paramDict: [String:String] = [ "client_id": config.clientId, "refresh_token": self.oauth2Session.refreshToken!]
        http.request(.POST, path: config.revokeTokenEndpoint!, parameters: paramDict, completionHandler: { (response, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }

            self.oauth2Session.clearTokens()
            completionHandler(response, nil)
        })
    }

    /**
    Gateway to login with OpenIDConnect

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    public override func login(completionHandler: (AnyObject?, OpenIDClaim?, NSError?) -> Void) {
        var openIDClaims: OpenIDClaim?

        self.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            if (error != nil) {
                completionHandler(nil, nil, error)
                return
            }
            let accessToken = response as? String
            if let accessToken = accessToken {
                let token = self.decode(accessToken)
                if let decodedToken = token {
                    openIDClaims = OpenIDClaim(fromDict: decodedToken)
                }
            }
            completionHandler(accessToken, openIDClaims, nil)
        }
    }

    /**
    Request to refresh an access token.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    public override func refreshAccessToken(completionHandler: (AnyObject?, NSError?) -> Void) {
        if let unwrappedRefreshToken = self.oauth2Session.refreshToken {
            var paramDict: [String: String] = ["refresh_token": unwrappedRefreshToken, "client_id": config.clientId, "grant_type": "refresh_token"]
            if (config.clientSecret != nil) {
                paramDict["client_secret"] = config.clientSecret!
            }

            http.request(.POST, path: config.refreshTokenEndpoint!, parameters: paramDict, completionHandler: { (response, error) in
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
                    self.oauth2Session.saveAccessToken(accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: expRefresh)
                    completionHandler(accessToken, nil)
                }
            })
        }
    }


    func decode(token: String) -> [String: AnyObject]? {
        let string = token.componentsSeparatedByString(".")
        let toDecode = string[1] as String


        var stringtoDecode: String = toDecode.stringByReplacingOccurrencesOfString("-", withString: "+") // 62nd char of encoding
        stringtoDecode = stringtoDecode.stringByReplacingOccurrencesOfString("_", withString: "/") // 63rd char of encoding
        switch (stringtoDecode.utf16.count % 4) {
        case 2: stringtoDecode = "\(stringtoDecode)=="
        case 3: stringtoDecode = "\(stringtoDecode)="
        default: // nothing to do stringtoDecode can stay the same
            print("")
        }
        let dataToDecode = NSData(base64EncodedString: stringtoDecode, options: [])
        let base64DecodedString = NSString(data: dataToDecode!, encoding: NSUTF8StringEncoding)

        var values: [String: AnyObject]?
        if let string = base64DecodedString {
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                values = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String : AnyObject]
            }
        }
        return values
    }

}
