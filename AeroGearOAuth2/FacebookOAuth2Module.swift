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

public class FacebookOAuth2Module: OAuth2Module {

    public required init(config: Config, session: OAuth2Session?, requestSerializer: RequestSerializer, responseSerializer: ResponseSerializer) {
        super.init(config: config, session: session, requestSerializer: JsonRequestSerializer(), responseSerializer: StringResponseSerializer())
    }
    
    override public func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: (AnyObject?, NSError?) -> Void) {
        var paramDict: [String: String] = ["code": code, "client_id": config.clientId, "redirect_uri": config.redirectURL, "grant_type":"authorization_code"]
        
        if let unwrapped = config.clientSecret {
            paramDict["client_secret"] = unwrapped
        }
        
        http.POST(config.accessTokenEndpoint, parameters: paramDict, completionHandler: { (response, error) in
            
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            if let unwrappedResponse = response as? String {
                var accessToken: String? = nil
                var expiredIn: String? = nil
                
                var charSet: NSMutableCharacterSet = NSMutableCharacterSet()
                charSet.addCharactersInString("&=")
                let array = unwrappedResponse.componentsSeparatedByCharactersInSet(charSet)
                for (index, elt) in enumerate(array) {
                    if elt == "access_token" {
                        accessToken = array[index+1]
                    }
                }
                for (index, elt) in enumerate(array) {
                    if elt == "expires" {
                        expiredIn = array[index+1]
                    }
                }
                //println("access:\(accessToken!) expires:\(expiredIn!)")
                self.oauth2Session.saveAccessToken(accessToken, refreshToken: nil, expiration: expiredIn)
                completionHandler(accessToken, nil)
            }
        })
    }
    
    override public func revokeAccess(completionHandler: (AnyObject?, NSError?) -> Void) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return;
        }
        let paramDict:[String:String] = ["access_token":self.oauth2Session.accessToken!]

        http.DELETE(config.revokeTokenEndpoint!, parameters: paramDict, completionHandler: { (response, error) in
            
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            self.oauth2Session.saveAccessToken()
            completionHandler(response!, nil)
        })
    }
}