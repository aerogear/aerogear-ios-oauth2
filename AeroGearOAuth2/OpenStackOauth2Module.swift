//
//  OpenStackOauth2Module.swift
//  AeroGearOAuth2
//
//  Created by Claudio on 9/18/15.
//  Copyright © 2015 aerogear. All rights reserved.
//

import AeroGearHttp

#if os(iOS)
import UIKit
import SafariServices
#endif

public class OpenStackOAuth2Module: OAuth2Module {
    
    public private(set) var isWebViewPresented = false
    
    /**
     Request an authorization code.
     
     :param: completionHandler A block object to be executed when the request operation finishes.
     */
    public override func requestAuthorizationCode(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // register with the notification system in order to be notified when the 'authorization' process completes in the
        // external browser, and the oauth code is available so that we can then proceed to request the 'access_token'
        // from the server.
        if applicationLaunchNotificationObserver == nil {
            applicationLaunchNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AGAppLaunchedWithURLNotification), object: nil, queue: nil, using: { (notification: Notification) -> () in
                #if os(iOS)
                self.extractCode(notification, completionHandler: completionHandler)
                if self.isWebViewPresented {
                    UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                }
                #endif
            })
        }
        
        // register to receive notification when the application becomes active so we
        // can clear any pending authorization requests which are not completed properly,
        // that is a user switched into the app without Accepting or Cancelling the authorization
        // request in the external browser process.
        if applicationDidBecomeActiveNotificationObserver == nil {
            applicationDidBecomeActiveNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AGAppDidBecomeActiveNotification), object:nil, queue:nil, using: { (note: Notification) -> () in
                // check the state
                if (self.state == .authorizationStatePendingExternalApproval) {
                    // unregister
                    self.stopObserving()
                    // ..and update state
                    self.state = .authorizationStateUnknown;
                }
            })
        }
        
        // update state to 'Pending'
        self.state = .authorizationStatePendingExternalApproval
        
        // calculate final url
        var params = "?scope=\(config.scope)&redirect_uri=\(config.redirectURL.urlEncode())&client_id=\(config.clientId)&response_type=code&nonce=\(generateNonce())"
        // add consent prompt for online_access scope http://openid.net/specs/openid-connect-core-1_0.html#OfflineAccess
        if config.scopes.contains("offline_access") {
            // force login on consent prompt
            let prompt = "login consent"
            params += "&prompt=\(prompt.urlEncode())"
        }
        
        let url = URL(string:http.calculateURL(baseURL: config.baseURL, url:config.authzEndpoint)!.absoluteString + params)
        #if os(iOS)
        if let url = url {
            if config.isWebView {
                let webView : UIViewController
                if #available(iOS 9.0, *) {
                    webView = SFSafariViewController(url: url)
                } else {
                    let webVC = OAuth2WebViewController()
                    webVC.targetURL = url
                    webView = webVC
                }
                UIApplication.shared.keyWindow?.rootViewController?.present(webView, animated: true, completion: { () -> () in
                    self.isWebViewPresented = true
                })
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        #endif
    }
    
    public override func revokeAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        // return if not yet initialized
        if (self.oauth2Session.accessToken == nil) {
            return;
        }
        var paramDict:[String:String] = [ "client_id": config.clientId]
        paramDict["secret"] = config.clientSecret
        paramDict["token"] = self.oauth2Session.accessToken!
        http.request(method: HttpMethod.post, path: config.revokeTokenEndpoint!, parameters: paramDict, completionHandler: { (response, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            self.oauth2Session.clearTokens()
            completionHandler(response as AnyObject, nil)
        })
    }
    
    /**
    Gateway to login with OpenIDConnect
    
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    public override func login(completionHandler: @escaping (AnyObject?, OpenIdClaim?, NSError?) -> Void) {
        var openIDClaims: OpenIdClaim?
        
        // hotfix to clear persistent tokens in keychain on login
        self.oauth2Session.clearTokens()
        
        super.requestAccess { (response: AnyObject?, error: NSError?) -> Void in
            if (error != nil) {
                completionHandler(nil, nil, error)
                return
            }
            
            if let unwrappedResponse = response as? [String: AnyObject] {
                let accessToken: String = unwrappedResponse["access_token"] as! String
                let refreshToken: String? = unwrappedResponse["refresh_token"] as? String
                let expiration = unwrappedResponse["expires_in"] as? NSNumber
                let exp: String? = expiration?.stringValue
                let expirationRefresh = unwrappedResponse["refresh_expires_in"] as? NSNumber
                let expRefresh = expirationRefresh?.stringValue
                
                // in Keycloak refresh token get refreshed every time you use them
                self.oauth2Session.save(accessToken: accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: expRefresh, idToken: nil)
                if let idToken =  unwrappedResponse["id_token"] as? String {
                    let token = self.decode(token: idToken)
                    if let decodedToken = token {
                        openIDClaims = OpenIdClaim(fromDict: decodedToken)
                    }
                }
                completionHandler(accessToken as AnyObject, openIDClaims, nil)
            }
            else {
                if let accessToken = response as? String {
                    completionHandler(accessToken as AnyObject, nil, nil)
                }
            }
        }
    }
    
    /**
     Gateway to request authorization access.
     
     :param: completionHandler A block object to be executed when the request operation finishes.
     */
    public override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        if (self.oauth2Session.accessToken != nil && self.oauth2Session.tokenIsNotExpired()) {
            // we already have a valid access token, nothing more to be done
            completionHandler(self.oauth2Session.accessToken! as AnyObject, nil);
        } else if (self.oauth2Session.refreshToken != nil && self.oauth2Session.refreshTokenIsNotExpired()) {
            // need to refresh token
            self.refreshAccessToken(completionHandler: completionHandler)
        } else if (self.config.isServiceAccount) {
            self.login() { (accessToken, claims, error) in
                completionHandler(accessToken, error)
            }
        } else {
            self.revokeAccess() { _ in }
            // error, must enforce user to request interactive login
            completionHandler(nil, NSError(domain: "OpenStackOAuth2Module", code: 8, userInfo: ["OpenStack OAuth2 Module": "User must do interactive login"]))
        }
    }
    
    /**
    Exchange an authorization code for an access token.
    
    :param: code the 'authorization' code to exchange for an access token.
    :param: completionHandler A block object to be executed when the request operation finishes.
    */
    public override func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        var paramDict: [String: String] = ["code": code, "client_id": config.clientId, "redirect_uri": config.redirectURL, "grant_type":"authorization_code"]
        
        if let unwrapped = config.clientSecret {
            paramDict["client_secret"] = unwrapped
        }
        
        http.request(method: HttpMethod.post, path: config.accessTokenEndpoint, parameters: paramDict, completionHandler: {(responseObject, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            if let unwrappedResponse = responseObject as? [String: AnyObject] {
                completionHandler(unwrappedResponse as AnyObject, nil)
            }
        })
    }
    
    func decode(token: String) -> [String: AnyObject]? {
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
        let dataToDecode = Data(base64Encoded: stringtoDecode, options: [])!
        let base64DecodedString = String(data: dataToDecode, encoding: String.Encoding.utf8)
        
        var values: [String: AnyObject]?
        if let string = base64DecodedString {
            if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
                values = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : AnyObject]
            }
        }
        return values
    }
    
    func generateNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let data = Data(bytes: bytes)
        return data.base64EncodedString()
    }
}

