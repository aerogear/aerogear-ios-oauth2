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

public class FacebookOAuth2Module: OAuth2Module {

    required public init(config: Config, accountId: String, session: OAuth2Session) {
        super.init(config: config, accountId: accountId, session: session)
        self.httpAuthz = Http(url: config.base, sessionConfig: NSURLSessionConfiguration.defaultSessionConfiguration(), requestSerializer: JsonRequestSerializer(url: NSURL(string: config.base), headers: [String: String]()), responseSerializer: StringResponseSerializer())
    }
    
    override public func exchangeAuthorizationCodeForAccessToken(code: String, success: SuccessType, failure: FailureType) {
        var paramDict: [String: String] = ["code": code, "client_id": config.clientId, "redirect_uri": config.redirectURL, "grant_type":"authorization_code"]
        
        if let unwrapped = config.clientSecret {
            paramDict["client_secret"] = unwrapped
        }
        
        httpAuthz.baseURL = config.accessTokenEndpointURL
        httpAuthz.POST(parameters: paramDict, success: {(responseObject: AnyObject?) -> () in
            if let unwrappedResponse = responseObject as? String {
                
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
                success(accessToken)
            }
            }, failure: {(error: NSError) -> () in
                failure(error)
        })
    }
    
    override public func revokeAccessSuccess(success: SuccessType, failure: FailureType) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return;
        }
        let paramDict:[String:String] = ["access_token":self.oauth2Session.accessToken!]
        httpAuthz.baseURL = config.revokeTokenEndpointURL!
        
        httpAuthz.DELETE(parameters: paramDict, success: { (param: AnyObject?) -> () in
            self.oauth2Session.saveAccessToken()
            success(param!)
            }, failure: { (error: NSError) -> () in
                failure(error)
        })
    }
}