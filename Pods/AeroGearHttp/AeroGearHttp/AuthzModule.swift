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
The protocol that authorization modules must adhere to.
*/
public protocol AuthzModule {

    /**
    Gateway to request authorization access.
    
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void)

    /**
    Request an authorization code.
    
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    func requestAuthorizationCode(completionHandler: @escaping (AnyObject?, NSError?) -> Void)

    /**
    Exchange an authorization code for an access token.
    
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: @escaping (AnyObject?, NSError?) -> Void)
    
    /**
    Request to refresh an access token.
    
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    func refreshAccessToken(completionHandler: @escaping (AnyObject?, NSError?) -> Void)
    
    /**
    Request to revoke access.
    
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void)
    
    /**
    Return any authorization fields.
    
   :returns:  a dictionary filled with the authorization fields.
    */
    func authorizationFields() -> [String: String]?
    
    /**
    Returns a boolean indicating whether authorization has been granted.
    
    :returns: true if authorized, false otherwise.
    */
    func isAuthorized() -> Bool
    
}
