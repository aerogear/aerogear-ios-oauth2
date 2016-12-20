//
//  TelenorConnectOAuth2Module.swift
//  Pods
//
//  Created by Jørund Fagerjord on 11/03/16.
//
//

import Foundation

import AeroGearHttp

public class TelenorConnectOAuth2Module: OAuth2Module {
    
    override public func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // TODO: also revoke refreshToken
        if (self.oauth2Session.accessToken == nil) {
            return;
        }
        let paramDict:[String:String] = [ "client_id": config.clientId, "token": self.oauth2Session.accessToken!]
        http.request(method: .post, path: config.revokeTokenEndpoint!, parameters: paramDict, responseSerializer: StringResponseSerializer(), completionHandler: { (response, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            self.oauth2Session.clearTokens()
            completionHandler(response as AnyObject?, nil)
        })
    }
}
