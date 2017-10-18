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
    
    override open func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        logOut(completionHandler: completionHandler)
    }
    
    private func logOut(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        guard
            let _ = self.config.logOutEndpoint,
            let _ = self.oauth2Session.refreshToken,
            let _ = self.oauth2Session.accessToken
            else {
                revokeAndClearTokens(completionHandler: completionHandler)
                return
        }
        
        if (self.oauth2Session.tokenIsNotExpired()) {
            callLogOutEndpoint(completionHandler: { (success, error) in
                self.revokeAndClearTokens(completionHandler: completionHandler)
            })
            return
        }
        
        self.refreshAccessToken(completionHandler: { (successRefresh, errorRefresh) in
            if (errorRefresh != nil) {
                self.revokeAndClearTokens(completionHandler: completionHandler)
                return
            }
            
            self.callLogOutEndpoint(completionHandler: { (successLogOut, errorLogOut) in
                self.revokeAndClearTokens(completionHandler: completionHandler)
            })
        })
    }
    
    private func callLogOutEndpoint(completionHandler: @escaping (Any?, NSError?) -> Void) {
        let http = Http(baseURL: self.config.baseURL)
        http.authzModule = self
        http.request(method: .post, path: config.logOutEndpoint!) { (response, error) in
            completionHandler(response, error)
        }
    }
    
    private func revokeAndClearTokens(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        revokeAccessToken()
        revokeRefreshToken()
        self.oauth2Session.clearTokens()
        completionHandler(nil, nil)
    }
    
    private func revokeAccessToken() {
        guard let accessToken = self.oauth2Session.accessToken else {
            return
        }
        let paramDict:[String:String] = [ "client_id": config.clientId, "token": accessToken]
        http.request(method: .post, path: config.revokeTokenEndpoint!, parameters: paramDict, responseSerializer: StringResponseSerializer(), completionHandler: { (response, error) in
        })
    }
    
    private func revokeRefreshToken() {
        guard let refreshToken = self.oauth2Session.refreshToken else {
            return
        }
        let paramDict:[String:String] = [ "client_id": config.clientId, "token": refreshToken]
        http.request(method: .post, path: config.revokeTokenEndpoint!, parameters: paramDict, responseSerializer: StringResponseSerializer(), completionHandler: { (response, error) in
        })
    }
}
