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
import AeroGearHttp

/**
An OAuth2Module subclass specific to 'Facebook' authorization
*/
open class FacebookOAuth2Module: OAuth2Module {

    public required init(config: Config, session: OAuth2Session?, requestSerializer: RequestSerializer = JsonRequestSerializer(), responseSerializer: ResponseSerializer = StringResponseSerializer()) {
        super.init(config: config, session: session, requestSerializer: JsonRequestSerializer(), responseSerializer: StringResponseSerializer())
    }

    /**
    Exchange an authorization code for an access token.

    :param: code the 'authorization' code to exchange for an access token.
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    override open func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        var paramDict: [String: String] = ["code": code, "client_id": config.clientId, "redirect_uri": config.redirectURL, "grant_type":"authorization_code"]

        if let unwrapped = config.clientSecret {
            paramDict["client_secret"] = unwrapped
        }

        http.request(method: .post, path: config.accessTokenEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in

            if (error != nil) {
                completionHandler(nil, error)
                return
            }

            if let unwrappedResponse = response as? String {
                var accessToken: String? = nil
                var expiredIn: String? = nil

                let charSet: NSMutableCharacterSet = NSMutableCharacterSet()
                charSet.addCharacters(in: "&=")
                let array = unwrappedResponse.components(separatedBy: charSet as CharacterSet)
                for (index, elt) in array.enumerated() {
                    if elt == "access_token" {
                        accessToken = array[index+1]
                    }
                }
                for (index, elt) in array.enumerated() {
                    if elt == "expires" {
                        expiredIn = array[index+1]
                    }
                }
                self.oauth2Session.save(accessToken: accessToken, refreshToken: nil, accessTokenExpiration: expiredIn, refreshTokenExpiration: nil, idToken: nil)
                completionHandler(accessToken as AnyObject?, nil)
            }
        })
    }

    /**
    Request to revoke access.

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    override open func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return
        }
        // return if no revoke endpoint
        guard let revokeTokenEndpoint = config.revokeTokenEndpoint else {
            return
        }

        let paramDict: [String:String] = ["access_token":self.oauth2Session.accessToken!]

        http.request(method: .delete, path: revokeTokenEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: { (response, error) in

            if (error != nil) {
                completionHandler(nil, error)
                return
            }

            self.oauth2Session.clearTokens()
            completionHandler(response! as AnyObject?, nil)
        })
    }

    /**
    Gateway to request authorization access

    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    override open func login(completionHandler: @escaping (AnyObject?, OpenIdClaim?, NSError?) -> Void) {
        self.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            if (error != nil) {
                completionHandler(nil, nil, error)
                return
            }
            var paramDict: [String: String] = [:]
            if response != nil {
                paramDict = ["access_token": response! as! String]
            }
            if let userInfoEndpoint = self.config.userInfoEndpoint {

                self.http.request(method: .get, path: userInfoEndpoint, parameters: paramDict as [String : AnyObject]?, completionHandler: {(responseObject, error) in
                    if (error != nil) {
                        completionHandler(nil, nil, error)
                        return
                    }
                    if let unwrappedResponse = responseObject as? String {
                        let data = unwrappedResponse.data(using: String.Encoding.utf8)
                        let json: AnyObject? = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0)) as AnyObject?
                        var openIDClaims: FacebookOpenIdClaim?
                        if let unwrappedResponse = json as? [String: AnyObject] {
                            openIDClaims = FacebookOpenIdClaim(fromDict: unwrappedResponse)
                        }
                        completionHandler(response, openIDClaims, nil)
                    }
                })
            } else {
                completionHandler(nil, nil, NSError(domain: "OAuth2Module", code: 0, userInfo: ["OpenID Connect" : "No UserInfo endpoint available in config"]))
                return
            }
        }
    }
}
